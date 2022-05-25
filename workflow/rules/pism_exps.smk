rule exp_taufac:
  output:
    main = expand("results/PISM_results/heinrich_taufac/heinrich_taufac{taufac}_NHEM_20km.nc", taufac=[0.006, 0.008, 0.01, 0.0125, 0.02, 0.04, 0.1  ]),
    ex   = expand("results/PISM_results/heinrich_taufac/ex_heinrich_taufac{taufac}_NHEM_20km.nc", taufac=[0.006, 0.008, 0.01, 0.0125, 0.02, 0.04, 0.1  ]),
    ts   = expand("results/PISM_results/heinrich_taufac/ts_heinrich_taufac{taufac}_NHEM_20km.nc", taufac=[0.006, 0.008, 0.01, 0.0125, 0.02, 0.04, 0.1  ]),

rule exp_taufac_single:
  output:
    main = "results/PISM_results/heinrich_taufac/heinrich_taufac0.006_NHEM_20km.nc",
    ex   = "results/PISM_results/heinrich_taufac/ex_heinrich_taufac0.006_NHEM_20km.nc",
    ts   = "results/PISM_results/heinrich_taufac/ts_heinrich_taufac0.006_NHEM_20km.nc",

rule exp_heinrich_tillphi:
  input:
    main      = "results/PISM_file/heinrich_tillphi_taufac{taufac}_{grid_name}.nc",
    refheight = "results/PISM_file/heinrich_tillphi_taufac{taufac}_{grid_name}_refheight.nc",
  output:
    main = "results/PISM_results/heinrich_taufac/heinrich_taufac{taufac}_{grid_name}.nc",
    ex   = "results/PISM_results/heinrich_taufac/ex_heinrich_taufac{taufac}_{grid_name}.nc",
    ts   = "results/PISM_results/heinrich_taufac/ts_heinrich_taufac{taufac}_{grid_name}.nc",
  shell:
    """
spack load pism-sbeyer@master

srun pismr \
  -bootstrap True \
  -timestep_hit_multiples 1 \
  -options_left True \
  -tauc_slippery_grounding_lines True \
  -stress_balance ssa+sia \
  -pseudo_plastic True \
  -Mx 625 \
  -My 625 \
  -Mz 101 \
  -Mbz 11 \
  -Lz 5000 \
  -Lbz 2000 \
  -calving eigen_calving,thickness_calving \
  -thickness_calving_threshold 200 \
  -ocean th \
  -ocean_th_period 1 \
  -part_grid True \
  -cfbc True \
  -kill_icebergs True \
  -eigen_calving_K 1e16 \
  -subgl True \
  -ocean.th.periodic True \
  -pdd_sd_period 1 \
  -atmosphere given,elevation_change \
  -atmosphere_given_period 1 \
  -temp_lapse_rate 0 \
  -surface pdd \
  -surface.pdd.factor_ice 0.019 \
  -surface.pdd.factor_snow 0.005 \
  -surface.pdd.refreeze 0.1 \
  -surface.pdd.std_dev.periodic True \
  -atmosphere.given.periodic True \
  -sia_e 2 \
  -ssa_e 1 \
  -pseudo_plastic_q 0.25 \
  -till_effective_fraction_overburden 0.02 \
  -ys 0 \
  -ye 100 \
  -ts_times 10 \
  -extra_times 100 \
  -extra_vars thk,velsurf_mag,tillwat,velbase_mag,mask,climatic_mass_balance,temppabase,ice_surface_temp,air_temp_snapshot,topg,tauc,velsurf,surface_runoff_flux,tendency_of_ice_amount_due_to_basal_mass_flux,tendency_of_ice_amount_due_to_discharge \
  -o {output.main} \
  -ts_file {output.ts} \
  -extra_file {output.ex} \
  -i {input.main} \
  -front_retreat_file {input.main} \
  -pdd_sd_file {input.main} \
  -atmosphere_lapse_rate_file {input.refheight} \
    """


rule exp_yearmean_compare_monthly:
  input:
    main      = "results/PISM_file/greenland_PD_GRN_20km.nc",
    refheight = "results/PISM_file/greenland_PD_GRN_20km_refheight.nc",
  output:
    main = "results/PISM_results/yearmean_compare/yearmean_compare_monthly.nc",
    ex   = "results/PISM_results/yearmean_compare/ex_yearmean_compare_monthly.nc",
    ts   = "results/PISM_results/yearmean_compare/ts_yearmean_compare_monthly.nc",
  shell:
    """
#spack load pism-sbeyer@master

mpirun -np 4 ~/pism-sbeyer/bin/pismr \
  -test_climate_models \
  -bootstrap True \
  -timestep_hit_multiples 1 \
  -options_left True \
  -stress_balance ssa+sia \
  -Mx 76 \
  -My 141 \
  -Mz 101 \
  -Mbz 11 \
  -Lz 4000 \
  -Lbz 2000 \
  -ocean pik \
  -atmosphere given \
  -surface pdd \
  -atmosphere.given.periodic True \
  -ys 0 \
  -ye 1 \
  -ts_times 1 \
  -extra_times daily \
  -extra_vars thk,climatic_mass_balance,ice_surface_temp,air_temp_snapshot,effective_air_temp,effective_precipitation,pdd_fluxes,pdd_rates \
  -o {output.main} \
  -ts_file {output.ts} \
  -extra_file {output.ex} \
  -i {input.main} \
  -front_retreat_file {input.main} \

    """
rule exp_yearmean_compare_yearly:
  input:
    main      = "results/PISM_file/greenland_PD_GRN_20km_yearmean.nc",
    refheight = "results/PISM_file/greenland_PD_GRN_20km_yearmean_refheight.nc",
  output:
    main = "results/PISM_results/yearmean_compare/yearmean_compare_yearmean.nc",
    ex   = "results/PISM_results/yearmean_compare/ex_yearmean_compare_yearmean.nc",
    ts   = "results/PISM_results/yearmean_compare/ts_yearmean_compare_yearmean.nc",
  shell:
    """
#spack load pism-sbeyer@master

mpirun -np 4 ~/pism-sbeyer/bin/pismr \
  -test_climate_models \
  -bootstrap True \
  -timestep_hit_multiples 1 \
  -options_left True \
  -stress_balance ssa+sia \
  -Mx 76 \
  -My 141 \
  -Mz 101 \
  -Mbz 11 \
  -Lz 4000 \
  -Lbz 2000 \
  -ocean pik \
  -atmosphere given \
  -surface pdd \
  -ys 0 \
  -ye 1 \
  -ts_times 1 \
  -extra_times daily \
  -extra_vars thk,climatic_mass_balance,ice_surface_temp,air_temp_snapshot,effective_air_temp,effective_precipitation,pdd_fluxes,pdd_rates \
  -o {output.main} \
  -ts_file {output.ts} \
  -extra_file {output.ex} \
  -i {input.main} \
  -front_retreat_file {input.main} \

    """

rule test_glacialindex:
  input:
    main      = "results/PISM_file/glacialindex_NHEM_20km.nc",
  output:
    main = "results/PISM_results/testglacialindex/testglacialindex.nc",
    ex   = "results/PISM_results/testglacialindex/ex_testglacialindex.nc",
    ts   = "results/PISM_results/testglacialindex/ts_testglacialindex.nc",
  shell:
    """

mpirun -np 4 ~/pism-sbeyer/bin/pismr \
  -bootstrap True \
  -timestep_hit_multiples 1 \
  -options_left True \
  -tauc_slippery_grounding_lines True \
  -Mx 625 \
  -My 625 \
  -Mz 101 \
  -Mbz 11 \
  -Lz 5000 \
  -Lbz 2000 \
  -calving eigen_calving,thickness_calving \
  -thickness_calving_threshold 200 \
  -ocean th \
  -ocean_th_period 1 \
  -ocean.th.periodic True \
  -part_grid True \
  -cfbc True \
  -kill_icebergs True \
  -eigen_calving_K 1e16 \
  -subgl True \
  -atmosphere_given_file {input.main} \
  -atmosphere index_forcing \
  -atmosphere_given_period 1 \
  -temp_lapse_rate 5 \
  -surface pdd \
  -surface.pdd.air_temp_all_precip_as_rain 275.15 \
  -surface.pdd.air_temp_all_precip_as_snow 271.15 \
  -surface.pdd.factor_ice 0.019 \
  -surface.pdd.factor_snow 0.005 \
  -surface.pdd.refreeze 0.1 \
  -surface.pdd.std_dev.periodic True \
  -atmosphere.given.periodic True \
  -atmosphere.index.periodic True \
  -sia_e 5 \
  -ssa_e 1 \
  -pseudo_plastic_q 0.4 \
   -till_effective_fraction_overburden 0.02 \
  -topg_to_phi 5,40,-300,700 \
  -ys -120000 \
  -ye -119900 \
  -ts_times 10 \
  -extra_times 100 \
  -extra_vars thk,usurf,velsurf_mag,bwat,velbase_mag,mask,climatic_mass_balance,effective_precipitation,effective_air_temp,temppabase, \
  -atmosphere_index_file {input.main} \
  -bed_def lc \
  -o {output.main} \
  -ts_file {output.ts} \
  -extra_file {output.ex} \
  -i {input.main} \
  -front_retreat_file {input.main} \
    """

