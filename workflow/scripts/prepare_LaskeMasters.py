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


def prepare_Laske_Masters(gridfile, input, outputfile, interpolationMethod):

    remapped_file = remap("{} ", gridfile, input,
                          "-f nc4c", interpolationMethod)

    nco.ncks(input=remapped_file,
             output=outputfile,)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate CESM Sediment file on icemodel grid")
    parser.add_argument("gridfile")
    parser.add_argument("inputfile")
    parser.add_argument("outputfile")
    parser.add_argument("--interpolationMethod", default="bilinear",
                        choices=["bilinear", "conservative"])
    args = parser.parse_args()
    prepare_Laske_Masters(args.gridfile,
                          args.inputfile,
                          args.outputfile,
                          args.interpolationMethod,
                          )
