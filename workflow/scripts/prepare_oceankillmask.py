
import sys
import numpy as np
import cv2 as cv
from netCDF4 import Dataset
import argparse


def generate_ocean_kill_mask(topgfile, outputfile, level=-2000, filter_length=25, remove_himalaya=False):

    topg_level = level

    src = Dataset(topgfile, "r")
    topg = src .variables["topg"][:]
    x = src .variables["x"][:]
    y = src .variables["y"][:]

    # new_thk = empty_like(topg)
    okill = np.zeros(topg.shape, dtype="uint8")

    # smoothing
    topg_smooth = cv.blur(topg, (filter_length, filter_length))

    #okill[topg_smooth>=topg_level] = 1.0
    np.putmask(okill, topg_smooth >= topg_level,
               1.0)  # a litle faster than previous method

    # second method using the longest contour
    # currently not used here
    #okill2 = np.zeros(topg.shape, dtype="uint8")
    # start image processing
    # https://stackoverflow.com/questions/44588279/find-and-draw-the-largest-contour-in-opencv-on-a-specific-color-python

    # work on initial data
    # im2, contours, hierarchy = cv.findContours(okill, cv.RETR_EXTERNAL,
    contours, hierarchy = cv.findContours(okill, cv.RETR_EXTERNAL,
                                          cv.CHAIN_APPROX_NONE)
    if len(contours) != 0:
        # find largest contour by area
        cnt = max(contours, key=cv.contourArea)
    else:
        print("ERROR: no contour found for given contour level")
        sys.exit(2)

    #print ("max area %f" % cv.contourArea(cnt))
    # mask based on selected contour
    # currently not used
    #cv.drawContours(okill2, [cnt], 0, 1, -1)

    if remove_himalaya:
        # option to remove ice in himalaya because the climate model is not so
        # great there
        okill[440:, 440:] = 0

    dst = Dataset(outputfile, "w")

    # Copy dimensions
    for dname, the_dim in src.dimensions.items():
        if dname in ['y', 'x']:
            # print(dname, len(the_dim))
            dst.createDimension(
                dname,
                len(the_dim) if not the_dim.isunlimited() else None)

    # Copy variables
    for vname, varin in src.variables.items():
        if vname in [
                'y',
                'x',
                'lat',
                'lon',
                'mapping',
        ]:
            out_var = dst.createVariable(vname, varin.datatype,
                                         varin.dimensions)
            # Copy variable attributes
            for att in varin.ncattrs():
                # print att
                if att not in ['_FillValue', 'name']:
                    setattr(out_var, att, getattr(varin, att))
            # Write data
            out_var[:] = varin[:]

    nc_mask = dst.createVariable('land_ice_area_fraction_retreat', 'd',
                                 ('y', 'x'))
    nc_mask[:] = okill
    nc_mask.units = "1"
    nc_mask.coordinates = "lat lon"
    nc_mask.long_name = "mask specifying fixed calving front locations"
    nc_mask.doc = 'ocean kill mask from topg_level {:.3f} m after smoothing with filter length {:d} pixel'.format(level, filter_length
                                                                                                                  )
    src.close()
    dst.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate ocean kill file based on topography")
    parser.add_argument("inputfile")
    parser.add_argument("outputfile")
    parser.add_argument("--level", default=-2000)
    parser.add_argument("--filter_length", default=25)
    parser.add_argument("--remove_himalaya", action="store_true")
    args = parser.parse_args()
    generate_ocean_kill_mask(args.inputfile,
                             args.outputfile,
                             level=args.level,
                             filter_length=args.filter_length,
                             remove_himalaya=args.remove_himalaya,
                             )
