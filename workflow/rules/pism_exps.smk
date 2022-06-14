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

def assemble_cmd_options(grid, climate, ocean,
                         bootstrap=True, periodic=True,
                         extra="standard",
                         time="startstop",
                         do_bed_deformation=False,
                         do_sealevel=False,
                         use_spack=False,
                         ):

    inout = [
        "-i {input.main}",
        "-o {output.main}",
        "-ts_file {output.ts}",
        "-extra_file {output.ex}",
      ]
    always_on = [
        "-options_left True",
        "-tauc_slippery_grounding_lines True",
        "-front_retreat_file {input.main}"
        ]
    grids = {
        "GRN_20km": ["-Mx  76 -My 141 -Mz 101 -Mbz 11 -Lz 4000 -Lbz 2000"],
        "NHEM_20km": ["-Mx 625 -My 625 -Mz 101 -Mbz 11 -Lz 5000 -Lbz 2000"],
        }
    marine_ice_sheets = [
        "-cfbc True",
        "-kill_icebergs True",
        "-part_grid True",
        "-subgl",
        ]
    calving = [
        "-calving eigen_calving,thickness_calving",
        "-thickness_calving_threshold 200"
        ]
    extra_vars = {
        "standard": ["-extra_vars thk,velsurf_mag,tillwat,velbase_mag,mask,climatic_mass_balance,temppabase,ice_surface_temp,air_temp_snapshot,topg,velsurf,surface_runoff_flux,tendency_of_ice_amount_due_to_basal_mass_flux,tendency_of_ice_amount_due_to_discharge"],
        }
    oceans = {
        "pik": ["-ocean pik"],
        "th": ["-ocean th"],
        }

    climate_forcings = {
        "PDD": [
            "-atmosphere given,elevation_change",
            "-atmosphere_lapse_rate_file {input.refheight}",
            "-temp_lapse_rate 5",
            "-surface pdd",
            "-surface.pdd.factor_ice 0.019",
            "-surface.pdd.factor_snow 0.005",
            "-surface.pdd.refreeze 0.1",
          ],
        "index_forcing": [
            "-atmosphere index_forcing",
            "-atmosphere_index_file {input.main}",
            "-surface pdd",
            "-surface.pdd.factor_ice 0.019",
            "-surface.pdd.factor_snow 0.005",
            "-surface.pdd.refreeze 0.1",
            "-test_climate_models",
          ],
        }
    dynamics = [
        "-stress_balance ssa+sia",
        "-pseudo_plastic True",
        "-sia_e 2",
        "-ssa_e 1",
        "-pseudo_plastic_q 0.25",
        "-till_effective_fraction_overburden 0.02",
        ]

    times = {
        "startstop": [
          "-ys {params.start}",
          "-ye {params.stop}",
          "-ts_times 10",
          "-extra_times monthly",
        ],
        "duration": [
          "-y {params.duration}",
          "-ts_times 10",
          "-extra_times 100",
        ],
        }

    sealevel = [
        "-sea_level constant,delta_sl",
        "-ocean_delta_sl_file {input.sealevel}",
        ]

    header_local = "mpirun -np 4 ~/pism-sbeyer/bin/pismr \\"
    header_spack = "spack load {params.spackpackage} \n \n srun pismr \\"

    if use_spack:
      header = header_spack
    else:
      header = header_local

    options = []
    if bootstrap:
        options += ["-bootstrap True"]
    options += always_on + grids[grid] + dynamics + marine_ice_sheets + climate_forcings[climate] + calving + extra_vars[extra] + inout + times[time]
    if ocean == "th" and periodic:
        options += ["-ocean.th.periodic True"]
    if periodic:
        options += ["-atmosphere.given.periodic True"]
        options += ["-surface.pdd.std_dev.periodic True"]
    if do_bed_deformation:
        options += ["-bed_def lc"]
    if do_sealevel:
        options += sealevel
    options_string = " \\\n".join(options)
    wholescript = header + "\n" + options_string
    return wholescript

rule test_cmd:
  input:
    main      = "results/PISM_file/greenland_PD_GRN_20km.nc",
    refheight = "results/PISM_file/greenland_PD_GRN_20km_refheight.nc",
  params:
    spackpackage = "pism-sbeyer@master"
  output:
    main = "results/PISM_results/multifile/multifile_test_time~{start}_{stop}.nc",
    ex   = "results/PISM_results/multifile/ex_multifile_test_time~{start}_{stop}.nc",
    ts   = "results/PISM_results/multifile/ts_multifile_test_time~{start}_{stop}.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="PDD", ocean="th", use_spack=False)

rule test_cmd2:
  input:
    main      = "results/PISM_results/multifile/multfile_test_time~{oldstart}_{start}.nc",
    refheight = "results/PISM_file/greenland_PD_GRN_20km_refheight.nc",
  params:
    spackpackage = "pism-sbeyer@master"
  output:
    main = "results/PISM_results/multifile/multifile_test_time_cont~{start}_{stop}.nc",
    ex   = "results/PISM_results/multifile/ex_multifile_test_time_cont~{start}_{stop}.nc",
    ts   = "results/PISM_results/multifile/ts_multifile_test_time_cont~{start}_{stop}.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="PDD", ocean="th", use_spack=False)

rule test_fake_glacialindex:
  input:
    main      = "results/PISM_file/test_glacialindex_GRN_20km.nc",
  params:
    spackpackage = "pism-sbeyer@master",
    start = 0,
    stop = 10,
  output:
    main = "results/PISM_results/test_fake_glacialindex/test_fake_glacialindex.nc",
    ex   = "results/PISM_results/test_fake_glacialindex/ex_test_fake_glacialindex.nc",
    ts   = "results/PISM_results/test_fake_glacialindex/ts_test_fake_glacialindex.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="index_forcing", ocean="th", use_spack=False)
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

