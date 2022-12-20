

## requirements
You need some python stuff that is listed in the env... Be sure to install pynco(?) from github, because the one on pypy is not working.

## grids
You need example grids to map the data onto. They are in 

## preparing CESM output for PISM
All scripts to generate input files are in `workflow/scripts/`.

CESM inputs need to be a climatology as the script by Ute/Matthias does.

### atmosphere:
```
./workflow/scripts/prepare_CESM_atmo.py <gridfile.nc> <CESM_input.nc> <CESM_standard_deviation_temp.nc> <output.nc> <output_reference_height.nc>
```

### ocean:
```
./workflow/scripts/prepare_CESM_ocean.py <gridfile.nc> <CESM_input.nc> <output.nc>
```


## assembling the PISM input files

- Heatflux files can be found in `results/heatflux/shapiro/`
- basal topography can be found in `results/topography/ETOPO1/`
- initial ice thickness data can be found in `results/topography/`. For example glac1D data here: `results/topography/GLAC1D/GLAC1D_nn9927_NaGrB_-21000k_thk_NHEM_20km.nc`
- oceankill (mask) can be found in `results/oceankill/`

This merges all the input components into one PISM input file:
```
ncks $ATMO $PISM_FILE
ncks -A $OCEAN $PISM_FILE
ncks -A -v bheatflx $HEATFLUX $PISM_FILE
ncks -A -v topg $BASAL_TOPOGRAPHY $PISM_FILE
ncks -A -v thk $INITIAL_ICETHICKNESS $PISM_FILE
ncks -A $OCEANKILL $PISM_FILE
```

> **Note**
> the reference height (used for lapse rate correction) has to be in a separate file.

## running PISM



This is an example slurm script:
```
#!/usr/bin/env bash

#SBATCH --partition=standard96
#SBATCH --nodes=8
#SBATCH --tasks-per-node=96
#SBATCH --time=12:00:00
#SBATCH --account=hbk00085
#SBATCH --output=pism_example.log.%j

spack load pism-sbeyer@current 
 
 srun pismr \
-i results/PISM_results_large/gi_cold_mprange_clemdyn/gi_cold_mprange_clemdyn_-10000_-5000.nc \
-front_retreat_file results/PISM_file/glacialindex_cold_tillphi_NHEM_20km.nc \
-o results/PISM_results_large/gi_cold_mprange_clemdyn/gi_cold_mprange_clemdyn_-5000_-0000.nc \
-ts_file results/PISM_results_large/gi_cold_mprange_clemdyn/ts_gi_cold_mprange_clemdyn_-5000_-0000.nc \
-extra_file results/PISM_results_large/gi_cold_mprange_clemdyn/ex_gi_cold_mprange_clemdyn_-5000_-0000.nc \
-atmosphere_index_file results/PISM_file/glacialindex_cold_tillphi_NHEM_20km.nc \
-ocean_delta_sl_file datasets/sealevel/pism_dSL_Imbrie2006.nc \
-ocean_th_file results/PISM_file/glacialindex_cold_tillphi_NHEM_20km.nc \
-time_stepping.maximum_time_step 1year \
-bootstrap False \
-ocean.th.periodic True \
-atmosphere.given.periodic True \
-surface.pdd.std_dev.periodic True \
-y 5000 \
-ts_times 10 \
-extra_times 100 \
-bed_def lc \
-sea_level constant,delta_sl \
-ocean th \
-Mx 625 -My 625 -Mz 101 -Mbz 11 -Lz 5000 -Lbz 2000 \
-extra_vars topg,thk,mask,velsurf_mag,velsurf,velbase_mag,tillwat,tauc,temppabase,climatic_mass_balance,effective_precipitation,effective_air_temp \
-atmosphere index_forcing \
-surface pdd \
-surface.pdd.factor_ice 0.019 \
-surface.pdd.factor_snow 0.005 \
-surface.pdd.refreeze 0.1 \
-surface.pdd.air_temp_all_precip_as_rain 275.15 \
-surface.pdd.air_temp_all_precip_as_snow 271.15 \
-stress_balance ssa+sia \
-pseudo_plastic True \
-sia_e 2.0 \
-ssa_e 1.0 \
-pseudo_plastic_q 0.25 \
-till_effective_fraction_overburden 0.02 \
-calving eigen_calving,thickness_calving \
-thickness_calving_threshold 200.0 \
-calving.eigen_calving.K 1e+17 \
-options_left True \
-tauc_slippery_grounding_lines True \
-timestep_hit_multiples 1 \
-backup_interval 5 \
-stress_balance.sia.max_diffusivity 100000 \
-geometry.ice_free_thickness_standard 10 \
-grid.registration corner \
-z_spacing equal \
-energy.enthalpy.temperate_ice_thermal_conductivity_ratio 0.01 \
-energy.basal_melt.use_grounded_cell_fraction False \
-cfbc True \
-kill_icebergs True \
-part_grid True \
-subgl \


```
