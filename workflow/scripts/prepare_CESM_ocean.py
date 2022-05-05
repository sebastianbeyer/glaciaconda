from gridfill import fill
import socket
from pathlib import Path
import tempfile
import os
import getpass
import numpy as np
from netCDF4 import Dataset
import argparse
import sys

from nco import Nco
from nco import custom as c
from cdo import Cdo
nco = Nco()

# todo: make this a config thing!
# on k19 I should use /work/sbeyer/tmp for tmp files
if socket.gethostname() == "k19":
    tempdir = "/work/"+getpass.getuser() + "/tmp"
    cdo = Cdo(tempdir=tempdir)  # python
else:
    cdo = Cdo()
    # cdo.debug = True


def fill_NaN(file, variable, setcornerstomean=False):
    """
    Fill NaN values with extrapolated values.
    Later this should use a better extrapolation, maybe as in ISMIP6
    https://zenodo.org/record/3997257
    @TODO: use with for dataset
    """
    # from gridfill import fill
    kw = dict(eps=1e-4,
              relax=0.6,
              itermax=1e3,
              initzonal=False,
              cyclic=False,
              verbose=True)

    rootgrp = Dataset(file, "r+")

    nc_var = rootgrp.variables[variable]

    if nc_var.ndim == 3:
        for step in range(nc_var.shape[0]):
            current = nc_var[step, :, :]
            if setcornerstomean:
                # set corner values to mean to avoid extrapolating into too low values
                mean = np.mean(current)
                current[0, 0] = mean
                current[-1, -1] = mean
                current[0, -1] = mean
                current[-1, 0] = mean

            filled, converged = fill(current, 1, 0, **kw)

            nc_var[step, :, :] = filled
    elif nc_var.ndim == 2:
        current = nc_var[:]
        filled, converged = fill(current, 1, 0, **kw)
        nc_var[:] = filled
    else:
        print("variable has to be 2d or 3d!")
        sys.exit()

    rootgrp.close()


def set_climatology_time(file):
    """
    For climatology forcing the time needs to start from 0
    @TODO: use with for dataset
    @TODO: middle of month?
    """
    secPerYear = 365.00 * 24 * 3600
    secPerMonth = secPerYear / 12
    timeMonths = np.arange(12)
    timeSecs = timeMonths * secPerMonth
    boundsMonths = np.array([[start, start + 1] for start in timeMonths])
    boundsSecs = boundsMonths * secPerMonth

    rootgrp = Dataset(file, "r+")
    if "nv" not in rootgrp.dimensions:
        print("creating nv dimension for time bounds")
        rootgrp.createDimension("nv", 2)

    nc_time = rootgrp.variables['time']
    nc_time[:] = timeSecs

    if "time_bnds" not in rootgrp.variables:
        print("creating time bounds var")
        nc_time_bounds = rootgrp.createVariable(
            "time_bnds", "f8", ("time", "nv"))
    nc_time_bounds = rootgrp.variables['time_bnds']
    nc_time_bounds[:] = boundsSecs
    print("done")
    nc_time.bounds = 'time_bnds'
    nc_time.units = 'seconds since 1-1-1'
    nc_time.calendar = '365_day'

    rootgrp.close()


def extract_variables(inputfile, variables):
    """
    pynco thinks that ncks is a SingleFileOperator and therefore
    the temporary output does not work there. This is a workaround for that.
    And also a wrapper for extracting variables.
    It returns the path of the resulting temp file
    @TODO: does it work with single vars?
    """
    # create a temporary file, use this as the output
    file_name_prefix = "nco_" + inputfile.split(os.sep)[-1]
    tmp_file = tempfile.NamedTemporaryFile(
        mode="w+b", prefix=file_name_prefix, suffix=".tmp", delete=False
    )
    output = tmp_file.name
    # cmd.append("--output={0}".format(output))

    options = "-v " + ','.join(variables)
    nco.ncks(input=inputfile, output=output, options=[
        options])
    return output


def remap(cdostring, gridfile, input, options, interpolationMethod):
    if interpolationMethod == "bilinear":
        remapped = cdo.remapbil(
            cdostring.format(gridfile), input=input, options=options)
    elif interpolationMethod == "conservative":
        remapped = cdo.remapycon(
            "{} ".format(gridfile), input=input, options=options)
    else:
        raise ValueError(
            'interpolationMethod {} unknown. Stopping.'.format(interpolationMethod))
    return remapped


def prepare_CESM_ocean(gridfile, inputfile, outputfile, interpolationMethod, compute_yearmean):

    # these were found using cdo showlevel, there is probably a better way
    # @TODO
    # also comment form Jorge: better use upper 400m or 200-1000m because that
    # is where shelfs are at around Antarctica
    upper200mlevels = "500,1500,2500,3500,4500,5500,6500,7500,8500,9500,10500,11500,12500,13500,14500,15500,16509.8398,17547.9043,18629.127,19766.0273"
    upper = cdo.vertmean(
        input="-setattribute,theta_ocean@units='Celsius' -chname,TEMP,theta_ocean -chname,SALT,salinity_ocean -sellevel,{} {}".format(upper200mlevels, inputfile))

    # using negative indexing to get lowest level
    # bottom_salt = cdo.sellevidx(-1, input=remapped)
    # ncks -d depth,-1 in.nc out.nc
    # opt = [
    #     c.LimitSingle("z_t", -1)
    # ]
    # # @TODO make wrapper for this tempfile stuff as well, I guess
    # nco.ncks(input=inputfile, output="bottom.nc", options=opt)

    remapped = remap("{} ", gridfile, upper,
                     "-f nc4c", interpolationMethod)

    opt = [
        c.Atted(mode="o", att_name="standard_name",
                var_name="theta_ocean", value="theta_ocean"),
        c.Atted(mode="o", att_name="long_name",
                var_name="theta_ocean", value="potential temperature of the adjacent ocean"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="salinity_ocean", value="salinity_ocean"),
        c.Atted(mode="o", att_name="long_name",
                var_name="salinity_ocean", value="ocean salinity"),
    ]
    nco.ncatted(input=remapped, options=opt)

    fill_NaN(remapped, "theta_ocean")
    fill_NaN(remapped, "salinity_ocean")

    if compute_yearmean:
        set_climatology_time(remapped)
        annualmean = cdo.yearmean(input=remapped)
        nco.ncks(input=annualmean,
                 output=outputfile)
    else:
        set_climatology_time(remapped)
        nco.ncks(input=remapped,
                 output=outputfile)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate CESM atmo file on icemodel grid")
    parser.add_argument("gridfile")
    parser.add_argument("inputfile")
    parser.add_argument("outputfile")
    parser.add_argument("--interpolationMethod", default="bilinear",
                        choices=["bilinear", "conservative"])
    parser.add_argument("--yearmean", action="store_true",
                        help="compute annual mean of data")
    args = parser.parse_args()
    prepare_CESM_ocean(args.gridfile,
                       args.inputfile,
                       args.outputfile,
                       args.interpolationMethod,
                       args.yearmean)
