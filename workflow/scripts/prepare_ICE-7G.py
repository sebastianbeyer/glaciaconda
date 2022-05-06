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


def prepare_ice7g(gridfile, input, outputfile, interpolationMethod):

    remapped = remap("{} -selvar,stgit,Topo", gridfile, input,
                     "-f nc4c -b F32", interpolationMethod)

    rDict = {
        'stgit': 'thk',
        'Topo': 'usurf',
    }
    nco.ncrename(input=remapped, options=[c.Rename("variable", rDict)])

    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="thk", value="m"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="thk", value="land_ice_thickness"),
        c.Atted(mode="o", att_name="long_name",
                var_name="thk", value=""),
        c.Atted(mode="o", att_name="source",
                var_name="thk", value="ICE-7G_NA https://www.atmosp.physics.utoronto.ca/~peltier/data.php"),
    ]
    nco.ncatted(input=remapped, options=opt)
    nco.ncks(input=remapped,
             output=outputfile)

    # topg is computed as difference
    topg = cdo.expr(
        "'topg = (usurf-thk)'", input=outputfile)
    opt = [
        c.Atted(mode="o", att_name="units",
                var_name="topg", value="m"),
        c.Atted(mode="o", att_name="standard_name",
                var_name="topg", value="bedrock_altitude"),
        c.Atted(mode="o", att_name="long_name",
                var_name="topg", value=""),
        c.Atted(mode="o", att_name="source",
                var_name="topg", value="ICE-7G_NA https://www.atmosp.physics.utoronto.ca/~peltier/data.php"),
    ]
    nco.ncatted(input=topg, options=opt)

    nco.ncks(input=topg,
             output=outputfile, append=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate CESM atmo file on icemodel grid")
    parser.add_argument("gridfile")
    parser.add_argument("inputfile")
    parser.add_argument("outputfile")
    parser.add_argument("--interpolationMethod", default="bilinear",
                        choices=["bilinear", "conservative"])
    args = parser.parse_args()
    prepare_ice7g(args.gridfile,
                  args.inputfile,
                  args.outputfile,
                  args.interpolationMethod,
                  )
