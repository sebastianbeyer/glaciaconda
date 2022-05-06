
import sys
import numpy as np
from netCDF4 import Dataset
import argparse


def generate_tillphi(topgfile, sedimentfile, maskfile, outfile,
                     sediment_threshold,
                     phi_min, phi_max, topg_min, topg_max, tauc_factor):

    # compute tillphi from topg:
    src = Dataset(topgfile, mode='r')
    topg = src.variables['topg'][:]

    print(sediment_threshold, phi_min, phi_max,
          topg_min, topg_max, tauc_factor)
    print(topg)

    tillphi = phi_min + (topg - topg_min) * \
        (phi_max-phi_min)/(topg_max-topg_min)
    tillphi[topg < topg_min] = phi_min
    tillphi[topg > topg_max] = phi_max

    # handle sediment map
    # first divide everything by 100 after a tan has been applied to it
    tillphi_rad = tillphi * np.pi / 180
    # tanphi = np.tan(tillphi_rad)  # for testing only

    m = (np.pi*0 + np.arctan(tauc_factor*np.tan(tillphi_rad))) / tillphi_rad
    smallphi_rad = tillphi_rad * m
    smallphi_deg = smallphi_rad / np.pi * 180
    # tanphi_small = np.tan(smallphi_rad)  # for testing only

    # determine where to reduce tillphi
    if maskfile != "none":
        data = Dataset(maskfile, mode="r")
        sedimask = data.variables['sedimentmask'][:]
        data.close()
        tillphi_sediment = np.where(
            sedimask > 0, tillphi, smallphi_deg)
    else:
        data = Dataset(sedimentfile, mode='r')
        thk_sediment = data.variables['thk_sediment'][:]
        data.close()
        tillphi_sediment = np.where(
            thk_sediment < sediment_threshold, tillphi, smallphi_deg)

    # write to the output file
    dst = Dataset(outfile, mode='w')

    ##############################################################
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

    nc_tillphi = dst.createVariable(
        'tillphi', 'f4', ('y', 'x'), zlib=True)
    nc_tillphi.units = "degrees"
    nc_tillphi.long_name = "till friction angle computed from topg and sediment mask"
    nc_tillphi[:] = tillphi_sediment

    src.close()
    dst.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate ocean kill file based on topography")
    parser.add_argument("topgfile")
    parser.add_argument("sedimentfile")
    parser.add_argument("maskfile")
    parser.add_argument("outfile")
    parser.add_argument("sediment_threshold", type=float)
    parser.add_argument("phi_min", type=float)
    parser.add_argument("phi_max", type=float)
    parser.add_argument("topg_min", type=float)
    parser.add_argument("topg_max", type=float)
    parser.add_argument("tauc_factor", type=float)
    args = parser.parse_args()

    generate_tillphi(args.topgfile,
                     args.sedimentfile,
                     args.maskfile,
                     args.outfile,
                     args.sediment_threshold,
                     args.phi_min,
                     args.phi_max,
                     args.topg_min,
                     args.topg_max,
                     args.tauc_factor)
