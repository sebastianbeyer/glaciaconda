import socket
from pathlib import Path
import tempfile
import os
import getpass
import numpy as np
from netCDF4 import Dataset
import argparse
import shutil

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


def set_climatology_time(file):
    """
    For climatology forcing the time needs to start from 0
    @TODO: use with for dataset
    @TODO: middle of month?
    """

    rootgrp = Dataset(file, "r+")
    if "nv" not in rootgrp.dimensions:
        print("creating nv dimension for time bounds")
        rootgrp.createDimension("nv", 2)

    nc_time = rootgrp.variables['time']
    nc_time[:] = [15, 45, 75, 105, 135, 165, 195, 225, 255, 285, 315, 345]

    if "time_bnds" not in rootgrp.variables:
        print("creating time bounds var")
        nc_time_bounds = rootgrp.createVariable(
            "time_bnds", "f8", ("time", "nv"))
    nc_time_bounds = rootgrp.variables['time_bnds']
    nc_time_bounds[:] = [[0, 30], [30, 60], [60, 90], [90, 120], [120, 150], [150, 180],
                         [180, 210], [210, 240], [240, 270], [270, 300], [300, 330], [330, 360]]
    print("done")
    nc_time.bounds = 'time_bnds'
    nc_time.units = 'days since 1-1-1'
    nc_time.calendar = '360_day'

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


def prepare_CESM_atmo(gridfile, inputfile, stddevfile, outputfile, outputfile_ref_Height, interpolationMethod, compute_yearmean):
    """
    Prepare CESM for use with PISM
    """
    # create a temporary file, use this as the output
    file_name_prefix = "cdoCESMatmo_" + inputfile.split(os.sep)[-1]
    tmp_file = tempfile.NamedTemporaryFile(
        mode="w+b", prefix=file_name_prefix, suffix=".tmp", delete=False
    )
    tmpfile = tmp_file.name

    extract_vars = ["PRECL", "PRECC", "TREFHT", "PHIS", "lat", "lon"]
    reduced_cesm = extract_variables(inputfile, extract_vars)

    remapped = remap("{} ", gridfile, reduced_cesm,
                     "-f nc4c", interpolationMethod)

    precipitation = cdo.expr(
        "'precipitation=(PRECL+PRECC)*60*60*24*365*1000'", input=remapped)  # convert to PISM units

    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="precipitation", value="kg m-2 yr-1"),
        c.Atted(mode="o", att_name="long_name",
                var_name="precipitation", value="mean monthly precipitation rate"),
    ]
    nco.ncatted(input=precipitation, options=opt)
    nco.ncks(input=precipitation,
             output=tmpfile)

    # temperature
    temperature = cdo.expr(
        "'air_temp=TREFHT'", input=remapped)  #

    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="air_temp", value="Kelvin"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="air_temp", value="air_temp"),
    ]
    nco.ncatted(input=temperature, options=opt)

    # this should fix the recurring issues with segfaults when assembling the
    # model file. I have no idea why this happens, but this might fix it
    # I'm sorry, future Sebi!!
    reduced_temp = extract_variables(temperature, ["air_temp"])
    nco.ncks(input=reduced_temp,
             output=tmpfile, append=True)

    # standard deviation
    stddevremapped = remap("{} ", gridfile, stddevfile,
                           "-f nc4c", interpolationMethod)

    temperature_stddev = cdo.expr(
        "'air_temp_sd=TREFHT'", input=stddevremapped)  #

    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="air_temp_sd", value="Kelvin"),
        c.Atted(mode="o", att_name="long_name",
                var_name="air_temp_sd", value="air temperature standard deviation"),
    ]
    nco.ncatted(input=temperature_stddev, options=opt)
    nco.ncks(input=temperature_stddev,
             output=tmpfile, append=True)
    set_climatology_time(tmpfile)

    if compute_yearmean:
        annualmean = cdo.yearmean(input=tmpfile)
        nco.ncks(input=annualmean,
                 output=outputfile)

    else:
        shutil.move(tmpfile, outputfile)

        # reference height
    ref_height = cdo.expr(
        "'referenceHeight=PHIS/9.81'", input=remapped)
    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="referenceHeight", value="m"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="referenceHeight", value="surface_altitude"),
    ]
    nco.ncatted(input=ref_height, options=opt)
    cdo.timmean(input=ref_height, output=outputfile_ref_Height,
                options='--reduce_dim')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate CESM atmo file on icemodel grid")
    parser.add_argument("gridfile")
    parser.add_argument("inputfile")
    parser.add_argument("stddevfile")
    parser.add_argument("outputfile")
    parser.add_argument("outputfile_ref_Height")
    parser.add_argument("--interpolationMethod", default="bilinear",
                        choices=["bilinear", "conservative"])
    parser.add_argument("--yearmean", action="store_true",
                        help="compute annual mean of data")
    args = parser.parse_args()
    prepare_CESM_atmo(args.gridfile,
                      args.inputfile,
                      args.stddevfile,
                      args.outputfile,
                      args.outputfile_ref_Height,
                      args.interpolationMethod,
                      args.yearmean)
