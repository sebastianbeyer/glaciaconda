#!/usr/bin/env python3
"""
Precompute the glacial index, so I don't need to implement it in PISM.
This will lead to different results, but hopefully they are not too diffrent.
"""
import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import argparse
from tqdm import tqdm


def check_monotonicity(vector):
    return np.all(vector[1:] >= vector[:-1])


def savitzky_golay(y, window_size, order, deriv=0, rate=1):
    r"""Smooth (and optionally differentiate) data with a Savitzky-Golay filter.
    The Savitzky-Golay filter removes high frequency noise from data.
    It has the advantage of preserving the original shape and
    features of the signal better than other types of filtering
    approaches, such as moving averages techniques.
    Parameters
    ----------
    y : array_like, shape (N,)
        the values of the time history of the signal.
    window_size : int
        the length of the window. Must be an odd integer number.
    order : int
        the order of the polynomial used in the filtering.
        Must be less then `window_size` - 1.
    deriv: int
        the order of the derivative to compute (default = 0 means only smoothing)
    Returns
    -------
    ys : ndarray, shape (N)
        the smoothed signal (or it's n-th derivative).
    Notes
    -----
    The Savitzky-Golay is a type of low-pass filter, particularly
    suited for smoothing noisy data. The main idea behind this
    approach is to make for each point a least-square fit with a
    polynomial of high order over a odd-sized window centered at
    the point.
    Examples
    --------
    t = np.linspace(-4, 4, 500)
    y = np.exp( -t**2 ) + np.random.normal(0, 0.05, t.shape)
    ysg = savitzky_golay(y, window_size=31, order=4)
    import matplotlib.pyplot as plt
    plt.plot(t, y, label='Noisy signal')
    plt.plot(t, np.exp(-t**2), 'k', lw=1.5, label='Original signal')
    plt.plot(t, ysg, 'r', label='Filtered signal')
    plt.legend()
    plt.show()
    References
    ----------
    .. [1] A. Savitzky, M. J. E. Golay, Smoothing and Differentiation of
       Data by Simplified Least Squares Procedures. Analytical
       Chemistry, 1964, 36 (8), pp 1627-1639.
    .. [2] Numerical Recipes 3rd Edition: The Art of Scientific Computing
       W.H. Press, S.A. Teukolsky, W.T. Vetterling, B.P. Flannery
       Cambridge University Press ISBN-13: 9780521880688
    """
    import numpy as np
    from math import factorial

    try:
        window_size = np.abs(np.int(window_size))
        order = np.abs(np.int(order))
    except ValueError:
        raise ValueError("window_size and order have to be of type int")
    if window_size % 2 != 1 or window_size < 1:
        raise TypeError("window_size size must be a positive odd number")
    if window_size < order + 2:
        raise TypeError("window_size is too small for the polynomials order")
    order_range = range(order+1)
    half_window = (window_size - 1) // 2
    # precompute coefficients
    b = np.mat([[k**i for i in order_range]
                for k in range(-half_window, half_window+1)])
    m = np.linalg.pinv(b).A[deriv] * rate**deriv * factorial(deriv)
    # pad the signal at the extremes with
    # values taken from the signal itself
    firstvals = y[0] - np.abs(y[1:half_window+1][::-1] - y[0])
    lastvals = y[-1] + np.abs(y[-half_window-1:-1][::-1] - y[-1])
    y = np.concatenate((firstvals, y, lastvals))
    return np.convolve(m[::-1], y, mode='valid')


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

    # convert time to seconds and invert direction
    time = time[::-1] * secPerYear * -1

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


def generate_index_file(ncfile_warm, ncfile_cold, ncfile_warm_ocean, ncfile_cold_ocean,
                        ncfile_warm_refheight, ncfile_cold_refheight,
                        index, time, time_bnds, outputfile, outputfile_refheight):

    def apply_index(T_PD, T_LGM, I_LGM, I_PD, I):
        T_index = T_PD + (T_LGM - T_PD) / (I_LGM - I_PD) * I
        return T_index

    with \
            xr.open_dataset(ncfile_cold, decode_times=False) as data_cold, \
            xr.open_dataset(ncfile_warm, decode_times=False) as data_warm, \
            xr.open_dataset(ncfile_cold_ocean, decode_times=False) as data_cold_ocean, \
            xr.open_dataset(ncfile_warm_ocean, decode_times=False) as data_warm_ocean, \
            xr.open_dataset(ncfile_warm_refheight, decode_times=False) as data_refheight_warm, \
            xr.open_dataset(ncfile_cold_refheight, decode_times=False) as data_refheight_cold:
        x = data_cold["x"]
        y = data_cold["y"]
        airtemp_cold = data_cold["air_temp"]
        airtempsd_cold = data_cold["air_temp_sd"]
        precip_cold = data_cold["precipitation"]

        airtemp_warm = data_warm["air_temp"]
        airtempsd_warm = data_warm["air_temp_sd"]
        precip_warm = data_warm["precipitation"]

        refheight_warm = data_refheight_warm["referenceHeight"]
        refheight_cold = data_refheight_cold["referenceHeight"]

        theta_ocean_warm = data_warm_ocean["theta_ocean"]
        theta_ocean_cold = data_cold_ocean["theta_ocean"]
        salinity_ocean_warm = data_warm_ocean["salinity_ocean"]
        salinity_ocean_cold = data_cold_ocean["salinity_ocean"]

        nt, ny, nx = airtemp_cold.shape

        airtemp_gi = np.empty((len(index), ny, nx))
        airtempsd_gi = np.empty((len(index), ny, nx))
        precip_gi = np.empty((len(index), ny, nx))
        theta_gi = np.empty((len(index), ny, nx))
        salinity_gi = np.empty((len(index), ny, nx))
        refheight_gi = np.empty((len(index), ny, nx))

        print("Interpolating fields using the index...")
        for i, gi in enumerate(tqdm(index)):
            pass
            # airtemp_gi[i, :, :] = apply_index(
            #     airtemp_warm, airtemp_cold, 1, 0, gi)
            # airtempsd_gi[i, :, :] = apply_index(
            #     airtempsd_warm, airtempsd_cold, 1, 0, gi)
            # precip_gi[i, :, :] = apply_index(
            #     precip_warm, precip_cold, 1, 0, gi)
            # theta_gi[i, :, :] = apply_index(
            #     theta_ocean_warm, theta_ocean_cold, 1, 0, gi)
            # salinity_gi[i, :, :] = apply_index(
            #     salinity_ocean_warm, salinity_ocean_cold, 1, 0, gi)
            # refheight_gi[i, :, :] = apply_index(
            #     refheight_warm, refheight_cold, 1, 0, gi)

            # ensure that precip does not go negative!
        precip_gi = np.clip(precip_gi, 0, None)

        #  precipitation correction due to surface elevation (H) change,
        #  based on the exponential relationship between water vapour
        #  saturation pressure and temperature in the upper atmosphere.
        #  See Niu et al. 2019 Eq. 5 doi:10.1017/jog.2019.42
        #
        # beta = 0.75  # km^-1
        # precip_gi = precip_gi * np.exp(-beta * elevation)
        #
        # print("monotonicity in write routine:")
        # print(check_monotonicity(time))
        # print(time)

        time_bnds_xr = xr.DataArray(name="time_bnds",
                                    data=time_bnds,
                                    dims=["time", "bnds"])

        airtemp_xr = xr.DataArray(name="air_temp",
                                  data=airtemp_gi,
                                  dims=["time", "y", "x"],
                                  coords={
                                      "time": time,
                                      "y": y,
                                      "x": x,
                                  },
                                  attrs=dict(
                                      long_name="Reference height temperature",
                                      standard_name="air_temp",
                                      units="Kelvin",
                                  ),
                                  )
        # print("time values in xarray")
        # print(airtemp_xr.time.values)
        airtempsd_xr = xr.DataArray(name="air_temp_sd",
                                    data=airtempsd_gi,
                                    dims=["time", "y", "x"],
                                    coords={
                                        "time": time,
                                        "y": y,
                                        "x": x,
                                    },
                                    attrs=dict(
                                        long_name="Reference height temperature standard deviation",
                                        units="Kelvin",
                                    ),
                                    )
        precip_xr = xr.DataArray(name="precipitation",
                                 data=precip_gi,
                                 dims=["time", "y", "x"],
                                 coords={
                                     "time": time,
                                     "y": y,
                                     "x": x,
                                 },
                                 attrs=dict(
                                     long_name="mean monthly precipitation rate",
                                     units="kg m-2 yr-1",
                                 ),
                                 )
        theta_xr = xr.DataArray(name="theta_ocean",
                                data=theta_gi,
                                dims=["time", "y", "x"],
                                coords={
                                    "time": time,
                                    "y": y,
                                    "x": x,
                                },
                                attrs=dict(
                                    long_name="potential temperature of the adjacent ocean",
                                    standard_name="theta_ocean",
                                    units="Celsius",
                                ),
                                )
        salinity_xr = xr.DataArray(name="salinity_ocean",
                                   data=salinity_gi,
                                   dims=["time", "y", "x"],
                                   coords={
                                       "time": time,
                                       "y": y,
                                       "x": x,
                                   },
                                   attrs=dict(
                                       long_name="ocean salinity",
                                       standard_name="salinity_ocean",
                                       units="gram/kilogram",
                                   ),
                                   )
        refheight_xr = xr.DataArray(name="referenceHeight",
                                    data=refheight_gi,
                                    dims=["time", "y", "x"],
                                    coords={
                                        "time": time,
                                        "y": y,
                                        "x": x,
                                    },
                                    attrs=dict(
                                        long_name="reference height used in the climate model",
                                        standard_name="surface_altitude",
                                        units="m",
                                    ),
                                    )

        output = xr.Dataset(
            dict(
                air_temp=airtemp_xr,
                air_temp_sd=airtempsd_xr,
                precipitation=precip_xr,
                theta_ocean=theta_xr,
                salinity_ocean=salinity_xr,
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
        encoding = {'x': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'y': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'time': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'time_bnds': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'precipitation': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'air_temp': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'air_temp_sd': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'theta_ocean': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    'salinity_ocean': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                    }
        output.to_netcdf(outputfile, encoding=None, engine="scipy")
        output.to_netcdf("output_nc4.nc", encoding=encoding,)

        # reference height goes into a different file
        output_refheight = xr.Dataset(
            dict(
                referenceHeight=refheight_xr,
                time_bnds=time_bnds_xr,
            )
        )
        output_refheight.time.attrs["standard_name"] = "time"
        output_refheight.time.attrs["long_name"] = "time"
        output_refheight.time.attrs["bounds"] = "time_bnds"
        output_refheight.time.attrs["units"] = "seconds since 1-1-1"
        output_refheight.time.attrs["calendar"] = "365_day"
        output_refheight.time.attrs["axis"] = "T"
        encoding_refheight = {'x': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                              'y': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                              'time': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                              'referenceHeight': {'dtype': 'float32', 'zlib': False, '_FillValue': None},
                              }
        output_refheight.to_netcdf(outputfile_refheight,
                                   encoding=encoding_refheight)

        # plt.figure()
        # plt.plot(airtemp_gi[:, 3, 3])
        # plt.show()
        # ncout = Dataset(outputfile, mode='w')

        # # should this be record dimension?
        # # ncout.createDimension('time', None)
        # ncout.createDimension('time', len(index))
        # nc_time_gi = ncout.createVariable('time', 'd', ('time', ))
        # nc_time_gi.units = 'seconds since 1-1-1'
        # nc_time_gi.calendar = '365_day'
        # nc_time_gi[:] = time
        # nc_gi = ncout.createVariable('glac_index', 'd', ('time'))
        # nc_gi[:] = index
        # nc_gi.units = '1'
        # ncout.close()
        #


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate CESM atmo file with precomputed glacial index forcing")
    parser.add_argument("warmfile")
    parser.add_argument("coldfile")
    parser.add_argument("warmfile_ocean")
    parser.add_argument("coldfile_ocean")
    parser.add_argument("warmfile_refheight")
    parser.add_argument("coldfile_refheight")
    parser.add_argument("indexfile")
    parser.add_argument("outputfile")
    parser.add_argument("outputfile_refheight")
    parser.add_argument("--filter", action="store_true",
                        help="Filter glacial index before using (to avoid aliasing effects)")
    parser.add_argument("--stride", type=int, default=20,
                        help="Only take every nth value of the index to reduce file size. (default=20)")
    args = parser.parse_args()

    index, time, time_ka, time_bnds_secs = read_csv_and_compute_index(
        args.indexfile)

    dt_years = (time_ka[5]-time_ka[4])*1000
    print(f"Delta t in csv is {dt_years} years")
    effective_dt = dt_years*20
    print(f"dt for stride={args.stride} is {effective_dt}")
    print(f"nt is {120000/effective_dt}")

    if args.filter:
        index = savitzky_golay(index, 51, 3)

    time_subset = time[::args.stride]
    time_bnds_subset = time_bnds_secs[::args.stride]
    index_subset = index[::args.stride]

    secPerYear = 60 * 60 * 24 * 365

    print("times in kyear")
    for i in range(len(time_subset)):
        print(
            f"{time_bnds_subset[i,0]/secPerYear/1000} {time_subset[i]/secPerYear/1000} {time_bnds_subset[i,1]/secPerYear/1000}")
    # print(time_subset/secPerYear / 1000)
    # print(time_bnds_subset/secPerYear / 1000)

    print("monotonicity:")
    print(check_monotonicity(time_subset))

    # calculate time bounds
    # boundsMonths = np.array([[start, start + 1] for start in timeMonths])
    # boundsSecs = boundsMonths * secPerMonth

    generate_index_file(args.warmfile, args.coldfile,
                        args.warmfile_ocean, args.coldfile_ocean,
                        args.warmfile_refheight, args.coldfile_refheight,
                        index_subset, time_subset, time_bnds_subset,
                        args.outputfile, args.outputfile_refheight)

# # plt.plot(time_ka, index, marker='o', markevery=5)
# # plt.plot(time_ka, index, marker='o', markevery=10,
# #          label="10", markeredgewidth=1.5, markeredgecolor="k")
# plt.plot(time_ka, index, marker='o', markevery=20,
#          label="20", markeredgewidth=1.5, markeredgecolor="k")
# plt.plot(time20, index20, label="simply every 20th")
# plt.plot(time_ka, index_filtered, label="filtered", marker='d',
#          markeredgewidth=1.5, markeredgecolor="k", markevery=20)
# plt.plot(time20, index20filt, label="filtered every 20th")
# plt.legend()

# plt.xlabel("time (ka)")
# plt.ylabel("glacial index")
# plt.savefig("glacialindex.png")
