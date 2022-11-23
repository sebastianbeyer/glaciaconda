from netCDF4 import Dataset

import numpy as np
import argparse
from scipy.signal import savgol_filter


def read_timeseries(file, variable):

    rootgrp = Dataset(file, "r")
    time = rootgrp.variables['time'][:]
    temp = rootgrp.variables[variable][:]

    rootgrp.close()
    return time, temp


def get_mean(file, variable):
    """
    read climatology and compute total mean
    """
    rootgrp = Dataset(file, "r")
    temp = rootgrp.variables[variable][:]
    mean = np.mean(temp)
    rootgrp.close()
    return mean


def write_delta_var_file(file, time, delta_var, varname):
    rootgrp = Dataset(file, "w")
    nc_time = rootgrp.createDimension("time", None)
    nc_times = rootgrp.createVariable("time", "f4", ("time",))
    nc_times.units = 'months since 1-1-1'
    nc_times.calendar = '360_day'
    nc_delta_T = rootgrp.createVariable(
        varname, "f4", ("time", ))
    if varname == "delta_T":
        nc_delta_T.units = "Kelvin"
    if varname == "delta_P":
        nc_delta_T.units = "kg m-2 yr-1"
    nc_times[:] = time
    nc_delta_T[:] = delta_var
    rootgrp.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate the delta_T or delta_P for PISM from time mean and climatology")
    parser.add_argument("timeseries")
    parser.add_argument("climatology")
    parser.add_argument("output")
    parser.add_argument("variable", help="variable for which to generate delta")
    parser.add_argument("--smoothing", type=float, default=0.0)
    parser.add_argument("--flattenall", action="store_true", help="make a file which is always zero")
    parser.add_argument("--skip", type=int, default=0)

    args = parser.parse_args()
    time, variable = read_timeseries(args.timeseries, args.variable)
    mean = get_mean(args.climatology, args.variable)
    print(f"Mean of climatology is {mean}.")

    delta_var = variable - np.mean(variable)
    time = np.arange(len(delta_var))

    if args.variable == "air_temp":
        varname = "delta_T"
    elif args.variable == "precipitation":
        varname = "delta_P"
    else:
        raise ValueError("only air_temp or precipitation are allowed so far")

    print(varname) 

        

    if args.smoothing != 0:
        delta_var = savgol_filter(delta_var, args.smoothing, 3, mode="wrap")

    if args.flattenall:
        delta_var[:] = 0

    if args.skip != 0:
        delta_var = delta_var[::args.skip]
        time = time[::args.skip]
    write_delta_var_file(args.output, time, delta_var, varname)
