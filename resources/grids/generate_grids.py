#!/usr/bin/env python3

import sys
import numpy as np
from time import asctime
from netCDF4 import Dataset
from pyproj import Proj, CRS


def create_grid_for_cdo_remap(grid, projection, is_initmip, nc_outfile):
    """
    Create a netcdf file holding the target grid for cdo
    """

    if is_initmip:
        import re
        grid_spacing = int(re.findall('\d+', name)
                           [-1]) * 1.e3  # convert km -> m
        # define output grid
        de = dn = grid_spacing  # m
        e0 = grid[2]
        n0 = grid[3]
        e1 = grid[4]
        n1 = grid[5]

        M = int((e1 - e0)/de) + 1
        N = int((n1 - n0)/dn) + 1

        easting = np.linspace(e0, e1, M)
        northing = np.linspace(n0, n1, N)

    else:
        grid_spacing = grid[4]
        # define output grid
        de = dn = grid_spacing  # m
        dxy = int(grid_spacing / 1e3)

        e0 = grid[2]
        n0 = grid[3]

        M = grid[0]
        N = grid[1]

        easting = np.linspace(e0, e0 + (M - 1) * de, M)
        northing = np.linspace(n0, n0 + (N - 1) * dn, N)

    ee, nn = np.meshgrid(easting, northing)

    print(M, N, easting[0], northing[0], easting[-1], northing[-1],
          np.diff(easting)[0],
          np.diff(northing)[0])

    proj = Proj(projection)
    crs = CRS.from_string(projection)

    lon, lat = proj(ee, nn, inverse=True)

    nc = Dataset(nc_outfile, 'w', format='NETCDF4_CLASSIC')

    nc.createDimension("x", size=easting.shape[0])
    nc.createDimension("y", size=northing.shape[0])

    var = 'x'
    var_out = nc.createVariable(var, 'float64', dimensions=("x"))
    var_out.units = "meters"
    var_out[:] = easting

    var = 'y'
    var_out = nc.createVariable(var, 'float64', dimensions=("y"))
    var_out.units = "meters"
    var_out[:] = northing

    var = 'lon'
    var_out = nc.createVariable(var,
                                'float64',
                                dimensions=("y", "x"),
                                zlib=True)
    var_out.units = "degreesE"
    var_out.bounds = "lon_bounds"
    var_out[:] = lon

    var = 'lat'
    var_out = nc.createVariable(var,
                                'float64',
                                dimensions=("y", "x"),
                                zlib=True)
    var_out.units = "degreesN"
    var_out.bounds = "lat_bounds"
    var_out[:] = lat

    var = 'dummy'
    var_out = nc.createVariable(var, 'b', dimensions=("y", "x"), zlib=True)
    var_out.units = ""
    var_out.comment = "dummy variable for CDO grid"
    # var_out.grid_mapping = "mapping"
    var_out.coordinates = "lon lat"
    var_out[:] = 0

    # proj_CF = crs.to_cf()
    # mapping = nc.createVariable("mapping", 'c')
    # mapping.ellipsoid = "WGS84"
    # mapping.false_easting = proj_CF['false_easting']
    # mapping.false_northing = proj_CF['false_northing']
    # mapping.grid_mapping_name = proj_CF['grid_mapping_name']
    # mapping.latitude_of_projection_origin = proj_CF[
    #     'latitude_of_projection_origin']
    # mapping.standard_parallel = proj_CF['standard_parallel']
    # mapping.straight_vertical_longitude_from_pole = proj_CF[
    #     'longitude_of_projection_origin']

    historystr = 'Created ' + asctime() + ' \n'
    nc.history = historystr
    # nc.comments = ''
    # nc.Conventions = 'CF-1.4'
    #

    nc.proj4 = proj.srs
    nc.close()

    print("Grid file", nc_outfile, "has been successfully written.")

    return nc_outfile


def prepare_ncfile_for_cdo(nc_outfile):
    """ This is a copy of the PISM nc2cdo.py code. """

    # open netCDF file in 'append' mode
    nc = Dataset(nc_outfile, 'a')

    # a list of possible x-dimensions names
    xdims = ['x', 'x1']
    # a list of possible y-dimensions names
    ydims = ['y', 'y1']

    # assign x dimension
    for dim in xdims:
        if dim in nc.dimensions.keys():
            xdim = dim
    # assign y dimension
    for dim in ydims:
        if dim in nc.dimensions.keys():
            ydim = dim

    # coordinate variable in x-direction
    x_var = nc.variables[xdim]
    # coordinate variable in y-direction
    y_var = nc.variables[ydim]

    # values of the coordinate variable in x-direction
    easting = x_var[:]
    # values of the coordinate variable in y-direction
    northing = y_var[:]

    # grid spacing in x-direction
    de = np.diff(easting)[0]
    # grid spacing in y-direction
    dn = np.diff(northing)[0]

    # number of grid points in x-direction
    M = easting.shape[0]
    # number of grid points in y-direction
    N = northing.shape[0]

    # number of grid corners
    grid_corners = 4
    # grid corner dimension name
    grid_corner_dim_name = "nv4"

    # array holding x-component of grid corners
    gc_easting = np.zeros((M, grid_corners))
    # array holding y-component of grid corners
    gc_northing = np.zeros((N, grid_corners))
    # array holding the offsets from the cell centers
    # in x-direction (counter-clockwise)
    de_vec = np.array([-de / 2, de / 2, de / 2, -de / 2])
    # array holding the offsets from the cell centers
    # in y-direction (counter-clockwise)
    dn_vec = np.array([-dn / 2, -dn / 2, dn / 2, dn / 2])
    # array holding lat-component of grid corners
    gc_lat = np.zeros((N, M, grid_corners))
    # array holding lon-component of grid corners
    gc_lon = np.zeros((N, M, grid_corners))

    proj = get_projection_from_file(nc)

    # If it does not yet exist, create dimension 'grid_corner_dim_name'
    if grid_corner_dim_name not in nc.dimensions.keys():
        for corner in range(0, grid_corners):
            ## grid_corners in x-direction
            gc_easting[:, corner] = easting + de_vec[corner]
            # grid corners in y-direction
            gc_northing[:, corner] = northing + dn_vec[corner]
            # meshgrid of grid corners in x-y space
            gc_ee, gc_nn = np.meshgrid(gc_easting[:, corner],
                                       gc_northing[:, corner])
            # project grid corners from x-y to lat-lon space
            gc_lon[:, :, corner], gc_lat[:, :, corner] = proj(gc_ee,
                                                              gc_nn,
                                                              inverse=True)

        nc.createDimension(grid_corner_dim_name, size=grid_corners)

        var = 'lon_bnds'
        # Create variable 'lon_bnds'
        var_out = nc.createVariable(var,
                                    'float64',
                                    dimensions=(ydim, xdim,
                                                grid_corner_dim_name),
                                    zlib=True)
        # Assign units to variable 'lon_bnds'
        var_out.units = "degreesE"
        # Assign values to variable 'lon_nds'
        var_out[:] = gc_lon

        var = 'lat_bnds'
        # Create variable 'lat_bnds'
        var_out = nc.createVariable(var,
                                    'float64',
                                    dimensions=(ydim, xdim,
                                                grid_corner_dim_name),
                                    zlib=True)
        # Assign units to variable 'lat_bnds'
        var_out.units = "degreesN"
        # Assign values to variable 'lat_bnds'
        var_out[:] = gc_lat

    if (not 'lon' in nc.variables.keys()) or (
            not 'lat' in nc.variables.keys()):
        print("No lat/lon coordinates found, creating them")
        ee, nn = np.meshgrid(easting, northing)
        lon, lat = proj(ee, nn, inverse=True)

    var = 'lon'
    # If it does not yet exist, create variable 'lon'
    if not var in nc.variables.keys():
        var_out = nc.createVariable(var, 'f', dimensions=(ydim, xdim))
        # Assign values to variable 'lon'
        var_out[:] = lon
    else:
        var_out = nc.variables[var]
    # Assign units to variable 'lon'
    var_out.units = "degreesE"
    # Assign long name to variable 'lon'
    var_out.long_name = "Longitude"
    # Assign standard name to variable 'lon'
    var_out.standard_name = "longitude"
    # Assign bounds to variable 'lon'
    var_out.bounds = "lon_bnds"

    var = 'lat'
    # If it does not yet exist, create variable 'lat'
    if not var in nc.variables.keys():
        var_out = nc.createVariable(var, 'f', dimensions=(ydim, xdim))
        var_out[:] = lat
    else:
        var_out = nc.variables[var]
    # Assign units to variable 'lat'
    var_out.units = "degreesN"
    # Assign long name to variable 'lat'
    var_out.long_name = "Latitude"
    # Assign standard name to variable 'lat'
    var_out.standard_name = "latitude"
    # Assign bounds to variable 'lat'
    var_out.bounds = "lat_bnds"

    # Make sure variables have 'coordinates' attribute
    for var in nc.variables.keys():
        if (nc.variables[var].ndim >= 2):
            nc.variables[var].coordinates = "lon lat"

    # lat/lon coordinates must not have mapping and coordinate attributes
    # if they exist, delete them
    for var in ['lat', 'lon', 'lat_bnds', 'lon_bnds']:
        if hasattr(nc.variables[var], 'grid_mapping'):
            delattr(nc.variables[var], 'grid_mapping')
        if hasattr(nc.variables[var], 'coordinates'):
            delattr(nc.variables[var], 'coordinates')

    # If present prepend history history attribute, otherwise create it
    from time import asctime
    histstr = asctime() + \
        ' : grid info for CDO added by nc2cdo.py, a PISM utility\n'
    if 'History' in nc.ncattrs():
        nc.History = histstr + str(nc.History)
    elif 'history' in nc.ncattrs():
        nc.history = histstr + str(nc.history)
    else:
        nc.history = histstr

    for attr in ("projection", "proj4"):
        if hasattr(nc, attr):
            delattr(nc, attr)
    # Write projection attribute
    # nc.proj4 = proj.srs
    # Close file
    nc.close()

    print("Prepared file", nc_outfile, "for cdo.")


def get_projection_from_file(nc):
    """ This is a copy of the PISM nc2cdo.py code. """

    # First, check if we have a global attribute 'proj4'
    # which contains a Proj4 string:
    try:
        p = Proj(str(nc.proj4))
        print(
            'Found projection information in global attribute proj4, using it')
    except:
        try:
            p = Proj(str(nc.projection))
            print(
                'Found projection information in global attribute projection, using it'
            )
        except:
            try:
                # go through variables and look for 'grid_mapping' attribute
                for var in nc.variables.keys():
                    print(var)
                    if hasattr(nc.variables[var], 'grid_mapping'):
                        mappingvarname = nc.variables[var].grid_mapping
                        print(
                            'Found projection information in variable "%s", using it'
                            % mappingvarname)
                        break
                var_mapping = nc.variables[mappingvarname]
                p = Proj(
                    proj="stere",
                    ellps=var_mapping.ellipsoid,
                    datum=var_mapping.ellipsoid,
                    units="m",
                    lat_ts=var_mapping.standard_parallel,
                    lat_0=var_mapping.latitude_of_projection_origin,
                    lon_0=var_mapping.straight_vertical_longitude_from_pole,
                    x_0=var_mapping.false_easting,
                    y_0=var_mapping.false_northing)
            except:
                print('No mapping information found, exiting.')
                sys.exit(1)

    return p


# grid_20km = [625, 625, -6240000, -6240000, 6240000, 6240000]
# grid_40km = [312, 312, -6240000, -6240000, 6240000, 6240000]
# grid_GRN_36km = [44, 76, -638000, -3349600, 864700, -657600]
# number of points in each direction M, N, first points in easting an northing
# and grid spacing:
# M, N, e0, n0, spacing
grid_10km = [1251, 1251, -6240000, -6240000, 10000]
grid_20km = [625, 625, -6240000, -6240000, 20000]
grid_40km = [312, 312, -6240000, -6240000, 40000]

grid_GRN_5km = [352, 608, -638000, -3349600, 5000]
grid_GRN_10km = [176, 304, -638000, -3349600, 10000]
grid_GRN_20km = [88, 152, -638000, -3349600, 20000]
grid_GRN_40km = [44, 76, -638000, -3349600, 40000]

# the corrected versions that have the same extent as the 20km version
# need to check with 40km as well and also for the complete NHEM
grid_GRN_10km = [175, 303, -638000, -3349600, 10000]
grid_GRN_5km = [349, 605, -638000, -3349600, 5000]

grid_GRN_Searise_20km = [76, 141, -800000, -3400000, 20000]
grid_GRN_Searise_20km = [76, 141, -650000, -3400000, 20000]

grids_initmip = {
    #    "initmip1km": [6081, 6081, -3040000, -3040000, 3040000, 3040000],
    #    "initmip2km": [3041, 3041, -3040000, -3040000, 3040000, 3040000],
    #    "initmip4km": [1521, 1521, -3040000, -3040000, 3040000, 3040000],
    "initmip8km": [761, 761, -3040000, -3040000, 3040000, 3040000],
    "initmip16km": [381, 381, -3040000, -3040000, 3040000, 3040000],
    "initmip32km": [191, 191, -3040000, -3040000, 3040000, 3040000],
    "initmip64km": [95, 95, -3040000, -3040000, 3040000, 3040000],
}


projectionNHEM = "+ellps=WGS84 +datum=WGS84 +lat_ts=71.0 +proj=stere +x_0=0.0 +units=m +lon_0=-44.0 +lat_0=90.0"
projectionGRN = "epsg:3413"
projectionInitmip = "+lon_0=0.0 +ellps=WGS84 +datum=WGS84 +lat_ts=-71.0 +proj=stere +x_0=0.0 +units=m +y_0=0.0 +lat_0=-90.0"

grids_nhem = [grid_10km, grid_20km, grid_40km]
grids_GRN = [grid_GRN_5km, grid_GRN_10km,
             grid_GRN_20km, grid_GRN_40km, ]

grids_Searise = [grid_GRN_Searise_20km]

for grid in grids_GRN:
    print(grid)
    filename = "CDO_grid_GRN_{}km.nc".format(grid[4] / 1000)
    projection = projectionGRN
    create_grid_for_cdo_remap(grid, projection, False, filename)
    prepare_ncfile_for_cdo(filename)

for grid in grids_nhem:
    print(grid)
    filename = "CDO_grid_NHEM_{}km.nc".format(grid[4] / 1000)
    projection = projectionNHEM
    create_grid_for_cdo_remap(grid, projection, False, filename)
    prepare_ncfile_for_cdo(filename)

for name, grid in grids_initmip.items():
    print(name, grid)
    filename = "CDO_grid_{}.nc".format(name)
    projection = projectionInitmip
    create_grid_for_cdo_remap(grid, projection, True, filename)
    prepare_ncfile_for_cdo(filename)

for grid in grids_GRN:
    print(grid)
    filename = "CDO_grid_GRN_{}km.nc".format(grid[4] / 1000)
    projection = projectionGRN
    create_grid_for_cdo_remap(grid, projection, False, filename)
    prepare_ncfile_for_cdo(filename)

for grid in grids_Searise:
    print(grid)
    filename = "CDO_grid_GRNSearise_{}km.nc".format(grid[4] / 1000)
    projection = projectionGRN
    create_grid_for_cdo_remap(grid, projection, False, filename)
    prepare_ncfile_for_cdo(filename)
