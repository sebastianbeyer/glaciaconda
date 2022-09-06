from netCDF4 import Dataset
import argparse


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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="set simple climatology time")
    parser.add_argument("inputfile")
    args = parser.parse_args()
    set_climatology_time(args.inputfile)
