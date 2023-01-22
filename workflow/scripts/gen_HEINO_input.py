#!/usr/bin/env python3

import numpy as np
from netCDF4 import Dataset
import argparse

parser = argparse.ArgumentParser(
    description="generate HEINO input file for PISM")
parser.add_argument('output')
parser.add_argument('--phisediment', type=float,
                    help="phi for sediment", default=10)
parser.add_argument('--phirock', type=float,
                    help="phi for rock", default=30)
parser.add_argument(
    '--experiment', choices=["ST", "T1", "T2", ], type=str, default="T1")


def write_netcdf(ncfile, x, y, topg, thk, icemask, smb, surface_temp, tillphi):
    root_grp = Dataset(ncfile, "w")
    root_grp.description = 'HEINO setup for PISM.'
    root_grp.createDimension('x', len(x))
    root_grp.createDimension('y', len(y))
    # root_grp.createDimension('time', None)

    # variables
    nc_x = root_grp.createVariable('x', 'f4', ('x',))
    nc_x.units = 'm'
    nc_x.axis = 'X'
    nc_x.long_name = 'X-coordinate in Cartesian system'
    nc_x.standard_name = 'projection_x_coordinate'

    nc_y = root_grp.createVariable('y', 'f4', ('y',))
    nc_y.units = 'm'
    nc_y.axis = 'Y'
    nc_y.long_name = 'Y-coordinate in Cartesian system'
    nc_y.standard_name = 'projection_y_coordinate'

    # now in meters
    nc_x[:] = x * 1000
    nc_y[:] = y * 1000

    nc_topg = root_grp.createVariable(
        "topg", 'f4', ('y', 'x'), zlib=True)
    nc_topg.units = "m"
    nc_topg.standard_name = "bedrock_altitude"
    # nc_topg.long_name = ""
    nc_topg[:] = topg

    nc_thk = root_grp.createVariable(
        "thk", 'f4', ('y', 'x'), zlib=True)
    nc_thk.units = "m"
    nc_thk.standard_name = "land_ice_thickness"
    # nc_thk.long_name = ""
    nc_thk[:] = thk

    nc_icemask = root_grp.createVariable(
        "land_ice_area_fraction_retreat", 'u1', ('y', 'x'), zlib=True)
    nc_icemask.units = "1"
    nc_icemask.standard_name = "land_ice_area_fraction_retreat"
    nc_icemask[:] = icemask

    nc_smb = root_grp.createVariable(
        "climatic_mass_balance", 'f4', ('y', 'x'), zlib=True)
    nc_smb.units = "kg m-2 year-1"
    nc_smb.standard_name = "land_ice_surface_specific_mass_balance_flux"
    nc_smb[:] = smb

    nc_temp = root_grp.createVariable(
        "ice_surface_temp", 'f4', ('y', 'x'), zlib=True)
    nc_temp.units = "Kelvin"
    nc_temp.standard_name = ""
    nc_temp[:] = surface_temp

    nc_tillphi = root_grp.createVariable(
        "tillphi", 'f4', ('y', 'x'), zlib=True)
    nc_tillphi.units = ""
    nc_tillphi.standard_name = ""
    nc_tillphi[:] = tillphi

    root_grp.close()


# smb is in m ice equivalent per year
EXPERIMENTS = {
    "ST": {"name": "ST", "b_min": 0.15, "b_max": 0.3, "T_min": 233.15},
    "T1": {"name": "T1", "b_min": 0.15, "b_max": 0.3, "T_min": 223.15},
    "T2": {"name": "T2", "b_min": 0.15, "b_max": 0.3, "T_min": 243.15},
    "B1": {"name": "B1", "b_min": 0.075, "b_max": 0.15, "T_min": 233.15},
    "B2": {"name": "B2", "b_min": 0.3, "b_max": 0.6, "T_min": 233.15},
}


# EXPERIMENTS = [ST, T1, T2, B1, B2]


def generateGeometry(phi_sediment, phi_rock, experiment, filename):
    # the following is in km
    x = np.linspace(0, 4000, num=81)
    y = np.linspace(0, 4000, num=81)

    X, Y = np.meshgrid(x, y)

    distance_from_center = np.sqrt((X - 2000) ** 2 + (Y - 2000) ** 2)
    radius = 2000

    ocean = distance_from_center >= radius
    land = distance_from_center < radius

    hudson_bay = np.logical_and.reduce(
        (2300 <= X, X <= 3300,
         1500 <= Y, Y <= 2500))

    hudson_strait = np.logical_and.reduce(
        (3300 < X, X <= 4000,
         1900 <= Y, Y <= 2100))

    topg = np.zeros_like(X) + 302
    topg = topg * land - 300
    thk = np.zeros_like(topg)

    topg[hudson_bay] -= 1
    topg[hudson_strait] -= 1

    # I could not find a way to describe different sliding laws at different
    # locations in PISM, so let's try with tillphi directly:
    tillphi = np.zeros_like(X) + phi_rock
    tillphi[hudson_bay] = phi_sediment
    tillphi[hudson_strait] = phi_sediment

    S_T = 2.5e-9  # Kelvin per kilometer cubed
    exp = EXPERIMENTS[experiment]
    smb = exp["b_min"] + (exp["b_max"] - exp["b_min"]) / \
        radius * distance_from_center
    # PISM units assuming ice density of 910
    smb = smb * 1000 * 0.91
    smb[ocean] = 0

    surface_temp = exp["T_min"] + S_T * distance_from_center**3
    # filename = "HEINO_4PISM_{}.nc".format(exp["name"])
    write_netcdf(filename, x, y, topg, thk, land,
                 smb, surface_temp, tillphi)


if __name__ == "__main__":
    args = parser.parse_args()
    print(args.experiment)
    generateGeometry(args.phisediment, args.phirock,
                     args.experiment, args.output)

