from netCDF4 import Dataset
import numpy as np
import argparse
from scipy.signal import savgol_filter


def read_temp_timeseries(file):

    rootgrp = Dataset(file, "r")
    time = rootgrp.variables['time'][:]
    temp = rootgrp.variables['air_temp'][:]

    rootgrp.close()
    return time, temp


def get_airtemp_mean(file):
    """
    read climatology and compute total mean
    """
    rootgrp = Dataset(file, "r")
    air_temp = rootgrp.variables['air_temp'][:]
    mean = np.mean(air_temp)
    rootgrp.close()
    return mean


def write_delta_T_file(file, time, delta_T):
    rootgrp = Dataset(file, "w")
    nc_time = rootgrp.createDimension("time", None)
    nc_times = rootgrp.createVariable("time", "f4", ("time",))
    nc_times.units = 'months since 1-1-1'
    nc_times.calendar = '360_day'
    nc_delta_T = rootgrp.createVariable(
        "delta_T", "f4", ("time", ))
    nc_delta_T.units = "Kelvin"
    nc_times[:] = time
    nc_delta_T[:] = delta_T
    rootgrp.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate the delta_T for PISM from time mean and climatology")
    parser.add_argument("temp_timeseries")
    parser.add_argument("climatology")
    parser.add_argument("output")
    parser.add_argument("--smoothing", type=float, default=0.0)
    parser.add_argument("--flattenall", action="store_true", help="make a file which is always zero")
    parser.add_argument("--skip", type=int, default=0)

    args = parser.parse_args()
    time, air_temp = read_temp_timeseries(args.temp_timeseries)
    mean = get_airtemp_mean(args.climatology)
    print(f"Mean of climatology is {mean} Kelvin.")

    delta_T = air_temp - np.mean(air_temp)
    time = np.arange(len(delta_T))
    if args.smoothing != 0:
        delta_T = savgol_filter(delta_T, args.smoothing, 3, mode="wrap")

    if args.flattenall:
        delta_T[:] = 0

    if args.skip != 0:
        delta_T = delta_T[::args.skip]
        time = time[::args.skip]
    write_delta_T_file(args.output, time, delta_T)
