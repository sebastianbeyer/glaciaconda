#!/usr/bin/env python3

import numpy as np
from netCDF4 import Dataset
import netCDF4 as nc
import argparse
import matplotlib.pyplot as plt
import matplotlib


params = {
    # 'text.latex.preamble': ['\\usepackage{gensymb}'],
    'image.origin': 'lower',
    'image.interpolation': 'nearest',
    'image.cmap': 'gray',
    'axes.grid': False,
    'savefig.dpi': 150,  # to adjust notebook inline plot size
    'axes.labelsize': 8,  # fontsize for x and y labels (was 10)
    'axes.titlesize': 8,
    'font.size': 8,  # was 10
    'legend.fontsize': 6,  # was 10
    'xtick.labelsize': 8,
    'ytick.labelsize': 8,
    # 'text.usetex': True,
    'figure.figsize': [3.39, 2.10],
    'font.family': 'serif',
}
matplotlib.rcParams.update(params)

parser = argparse.ArgumentParser(
    description='',)

parser.add_argument('pism_ts_file')
parser.add_argument('output')
parser.add_argument('--observed', help="obseverd sea level change e.g. imbrie2006", default="none")
parser.add_argument('--usetex', help="use latex to improve some font rendering")
args = parser.parse_args()

if args.usetex:
    params['text.usetex'] = True
    params['text.latex.preamble'] = ['\\usepackage{gensymb}']

rootgrp = nc.MFDataset(args.pism_ts_file, "r")
time = rootgrp.variables['time'][:]
volume = rootgrp.variables['ice_volume'][:]
sealevel_pism = rootgrp.variables['sea_level_rise_potential'][:]
rootgrp.close()

    # "/home/sebastian/palmod/datasets/automaticIceData/input/sealevel/pism_dSL_Imbrie2006.nc", "r")
if args.observed != "none":
    rootgrp = Dataset(args.observed, "r")
    time_imbrie = rootgrp.variables['time'][:]
    sealevel_imbrie = rootgrp.variables['delta_SL'][:]
    rootgrp.close()
    time_imbrie = time_imbrie / 1000

# time_imbrie = time_imbrie * 60 * 60 * 24 * 365
time = time / (60 * 60 * 24 * 365) / 1000

plt.figure(figsize=(5, 2.5))
plt.plot(time, -sealevel_pism, label="PISM", color="darkorange")
if args.observed != "none":
    plt.plot(time_imbrie, sealevel_imbrie, label="Imbrie 2006", color="grey")
plt.xlabel("time (ka)")
plt.ylabel("sea level (m)")
plt.legend(frameon=False)

plt.gca().spines["top"].set_alpha(0.0)
plt.gca().spines["bottom"].set_alpha(0.3)
plt.gca().spines["right"].set_alpha(0.0)
plt.gca().spines["left"].set_alpha(0.3)

plt.tight_layout()
plt.savefig(args.output, dpi=300)

# plt.show()
