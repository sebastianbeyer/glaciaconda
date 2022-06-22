#!/usr/bin/env python3
"""
compute the glacial index
"""
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import argparse


def generate_fake_index():
    """
    Prepare glacial index file
    """
    secPerYear = 60 * 60 * 24 * 365

    time_bnds = [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
        [4, 5],
        [5, 6],
        [6, 7],
        [7, 8],
        [8, 9],
        [9, 10],
        [10, 11],
        [11, 12],
        [12, 13],
        [13, 14],
        [14, 15],
        [15, 16],
        [16, 17],
        [17, 18],
        [18, 19],
        [19, 20],
        [20, 21],
        [21, 22],
        [22, 23],
    ]
    time_bnds = np.array(time_bnds)
    time_bnds_secs = time_bnds * secPerYear

    # compute time from bounds
    time = np.mean(time_bnds_secs, axis=1)
    index = (np.sin(time/secPerYear) + 1) / 2

    return index, time, time_bnds_secs


def generate_index_file(index, time, time_bnds, outputfile):

    time_bnds_xr = xr.DataArray(name="time_bnds",
                                data=time_bnds,
                                dims=["time", "bnds"])

    index_xr = xr.DataArray(name="glac_index",
                            data=index,
                            dims=["time"],
                            coords={
                                "time": time,
                            },
                            attrs=dict(
                                long_name="Glacial Index",
                                units="1",
                            ),
                            )

    output = xr.Dataset(
        dict(
            glac_index=index_xr,
            time_bnds=time_bnds_xr,
        )
    )
    output.time.attrs["standard_name"] = "time"
    output.time.attrs["long_name"] = "time"
    output.time.attrs["bounds"] = "time_bnds"
    output.time.attrs["units"] = "seconds since 1-1-1"
    output.time.attrs["calendar"] = "365_day"
    output.time.attrs["axis"] = "T"

    # set encoding, otherwise we have fillValue even in coordinates and
    # time and that's not CF compliant.
    encoding = {
        'time': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
        'time_bnds': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
    }
    output.to_netcdf(outputfile, encoding=None, engine="scipy")
    # output.to_netcdf("output_nc4.nc", encoding=encoding,)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate glacial index forcing")
    parser.add_argument("outputfile")
    args = parser.parse_args()

    index, time, time_bnds_sec = generate_fake_index()

    generate_index_file(
        index, time, time_bnds_sec,
        args.outputfile)
