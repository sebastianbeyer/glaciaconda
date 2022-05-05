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


def prepare_ETOPO1(gridfile, input_bed, input_usurf, outputfile, interpolationMethod):

    remapped_bed = remap("{} ", gridfile, input_bed,
                         "-f nc4c", interpolationMethod)

    rDict = {
        'z': 'topg',
    }
    nco.ncrename(input=remapped_bed, options=[c.Rename("variable", rDict)])

    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="topg", value="m"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="topg", value="bedrock_altitude"),
        c.Atted(mode="o", att_name="long_name",
                var_name="topg", value=""),
        c.Atted(mode="o", att_name="source",
                var_name="topg", value="ETOPO1 1 Arc-Minute Global Relief Model. http://www.ngdc.noaa.gov/mgg/global/global.html"),
    ]
    nco.ncatted(input=remapped_bed, options=opt)
    nco.ncks(input=remapped_bed,
             output=outputfile)

    remapped_usurf = remap("{} ", gridfile, input_usurf,
                           "-f nc4c", interpolationMethod)

    rDict = {
        'z': 'usurf',
    }
    nco.ncrename(input=remapped_usurf, options=[c.Rename("variable", rDict)])

    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="usurf", value="m"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="usurf", value="surface_altitude"),
        c.Atted(mode="o", att_name="long_name",
                var_name="usurf", value=""),
        c.Atted(mode="o", att_name="source",
                var_name="usurf", value="ETOPO1 1 Arc-Minute Global Relief Model. http://www.ngdc.noaa.gov/mgg/global/global.html"),
    ]
    nco.ncatted(input=remapped_usurf, options=opt)

    nco.ncks(input=remapped_usurf,
             output=outputfile, append=True)

    # thickness is computed from usurf and topg
    # need to make sure that it's always positive
    thk = cdo.expr(
        "'thk = ((usurf-topg) > 0) ? (usurf-topg) : (0.0)'", input=outputfile, options="-f nc4c")
    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="thk", value="m"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="thk", value="land_ice_thickness"),
        c.Atted(mode="o", att_name="long_name",
                var_name="thk", value=""),
        c.Atted(mode="o", att_name="source",
                var_name="thk", value="ETOPO1 1 Arc-Minute Global Relief Model. http://www.ngdc.noaa.gov/mgg/global/global.html"),
    ]
    nco.ncatted(input=thk, options=opt)

    nco.ncks(input=thk,
             output=outputfile, append=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate ETOPO1 file on icemodel grid")
    parser.add_argument("gridfile")
    parser.add_argument("input_bed")
    parser.add_argument("input_usurf")
    parser.add_argument("outputfile")
    parser.add_argument("--interpolationMethod", default="bilinear",
                        choices=["bilinear", "conservative"])
    args = parser.parse_args()
    prepare_ETOPO1(args.gridfile,
                   args.input_bed,
                   args.input_usurf,
                   args.outputfile,
                   args.interpolationMethod,
                   )
