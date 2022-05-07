rule testslurm:
  input:
    main      = "results/PISM_file/heinrich_tillphi_taufac0.01_NHEM_20km.nc",
    refheight = "results/PISM_file/heinrich_tillphi_taufac0.01_NHEM_20km_refheight.nc",
  output:
    main = "results/PISM_results/exp1/test.nc",
    ex   = "results/PISM_results/exp1/ex_test.nc",
    ts   = "results/PISM_results/exp1/ts_test.nc",
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
  -temp_lapse_rate 5 \
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
  -extra_vars thk,velsurf_mag,tillwat,velbase_mag,mask,climatic_mass_balance,tendency_of_ice_amount_due_to_flow,tendency_of_ice_amount_due_to_surface_mass_flux,tendency_of_ice_amount,surface_accumulation_flux,effective_precipitation,effective_air_temp,temppabase,ice_surface_temp,air_temp_snapshot \
  -o {output.main} \
  -ts_file {output.ts} \
  -extra_file {output.ex} \
  -i {input.main} \
  -front_retreat_file {input.main} \
  -pdd_sd_file {input.main} \
  -atmosphere_lapse_rate_file {input.refheight} \


    """
