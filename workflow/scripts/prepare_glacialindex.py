#!/usr/bin/env python3
"""
compute the glacial index
"""
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import argparse
from tqdm import tqdm


def check_monotonicity(vector):
    return np.all(vector[1:] >= vector[:-1])


def read_csv_and_compute_index(csvfile):
    """
    Prepare glacial index file
    """
    # input = "./input/glacialIndex/41586_2004_BFnature02805_MOESM1_ESM.csv"
    secPerYear = 60 * 60 * 24 * 365

    deltaO18 = np.genfromtxt(csvfile, delimiter=',')
    # the csv uses inverval notation, so every year is double
    # lets only take every second one

    time = deltaO18[::2, 0] / 1000  # no idea why I need to do that...¬
    delta = deltaO18[::2, 1]

    # compute bounds
    time_bnds = deltaO18[::-1, 0] * -1  # reverse direction
    time_bnds = time_bnds.reshape((len(time_bnds)//2, 2))
    time_bnds = time_bnds / 1000  # now it's years

    time_bnds_secs = time_bnds * secPerYear

    # compute time from bounds
    time = np.mean(time_bnds_secs, axis=1)

    # convert time to seconds and invert direction
    # time = time[::-1] * secPerYear * -1

    # also need to reverse the delta
    delta = delta[::-1]

    LGMindex = len(delta) - 421  # at 21k years before present (year 2000)
    IGindex = len(delta) - 1  # interglacial is now

    print('LGM time is {} ka'.format(time[LGMindex] / secPerYear / 1000))
    print('IG time is {} ka'.format(time[IGindex] / secPerYear / 1000))

    def gen_index(delta, deltaPD, deltaLGM):
        """Eq. 1 in Niu et al 2017"""
        return (delta - deltaPD) / (deltaLGM - deltaPD)

    index = gen_index(delta, delta[IGindex], delta[LGMindex])
    time_ka = time / secPerYear/1000

    return index, time, time_ka, time_bnds_secs


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
    parser.add_argument("indexfile")
    parser.add_argument("outputfile")
    args = parser.parse_args()

    index, time, time_ka, time_bnds_sec = read_csv_and_compute_index(
        args.indexfile)

    generate_index_file(
        index, time, time_bnds_sec,
        args.outputfile)
