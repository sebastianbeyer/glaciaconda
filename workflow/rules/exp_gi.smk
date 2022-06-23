configfile: "config/config.yaml"
print(config)

def assemble_cmd_options(grid, climate, ocean,
                         bootstrap=True, periodic=True,
                         extra="standard",
                         time="startstop",
                         do_bed_deformation=False,
                         do_sealevel=False,
                         use_spack=False,
                         ):

    inout = [
        "-i {input.restart}",
        "-o {output.main}",
        "-ts_file {output.ts}",
        "-extra_file {output.ex}",
      ]
    always_on = [
        "-options_left True",
        "-tauc_slippery_grounding_lines True",
        "-front_retreat_file {input.main}",
        "-timestep_hit_multiples 1",
        "-backup_interval 5",
        "-stress_balance.sia.max_diffusivity 100000",
        "-grid.registration corner",
        "-z_spacing equal",
        "-energy.enthalpy.temperate_ice_thermal_conductivity_ratio 0.01"
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
        "th": ["-ocean th", "-ocean_th_file {input.main}"],
        }

    climate_forcings = {
        "PDD": [
            "-atmosphere given,elevation_change",
            "-atmosphere_lapse_rate_file {input.refheight}",
            f"-temp_lapse_rate {config['climate']['mprange']['temp_lapse_rate']}",
            "-surface pdd",
            f"-surface.pdd.factor_ice {config['climate']['mprange']['pdd_factor_ice']}",
            f"-surface.pdd.factor_snow {config['climate']['mprange']['pdd_factor_snow']}",
            f"-surface.pdd.refreeze {config['climate']['mprange']['pdd_refreeze']}",
            f"-surface.pdd.air_temp_all_precip_as_rain {config['climate']['mprange']['air_temp_all_precip_as_rain']}",
            f"-surface.pdd.air_temp_all_precip_as_snow {config['climate']['mprange']['air_temp_all_precip_as_snow']}",
          ],
        "index_forcing": [
            "-atmosphere index_forcing",
            "-atmosphere_index_file {input.main}",
            "-surface pdd",
            f"-surface.pdd.factor_ice {config['climate']['mprange']['pdd_factor_ice']}",
            f"-surface.pdd.factor_snow {config['climate']['mprange']['pdd_factor_snow']}",
            f"-surface.pdd.refreeze {config['climate']['mprange']['pdd_refreeze']}",
            f"-surface.pdd.air_temp_all_precip_as_rain {config['climate']['mprange']['air_temp_all_precip_as_rain']}",
            f"-surface.pdd.air_temp_all_precip_as_snow {config['climate']['mprange']['air_temp_all_precip_as_snow']}",
          ],
        }
    dynamics = [
        "-stress_balance ssa+sia",
        "-pseudo_plastic True",
        f"-sia_e {config['dynamics']['heinrich']['sia_e']}",
        f"-ssa_e {config['dynamics']['heinrich']['ssa_e']}",
        f"-pseudo_plastic_q {config['dynamics']['heinrich']['pseudo_plastic_q']}",
        f"-till_effective_fraction_overburden {config['dynamics']['heinrich']['till_effective_fraction_overburden']}",
        ]

    times = {
        "startstop": [
          "-ys {params.start}",
          "-ye {params.stop}",
          "-ts_times {params.ts_times}",
          "-extra_times {params.ex_times}",
        ],
        "duration": [
          "-y {params.duration}",
          "-ts_times {params.ts_times}",
          "-extra_times {params.ex_times}",
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
    options += always_on + grids[grid] + dynamics + marine_ice_sheets + climate_forcings[climate] + calving + oceans[ocean]+ extra_vars[extra] + inout + times[time]
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


rule test_multirun_first:
  input:
    main      = "results/PISM_file/test_glacialindex_GRN_20km.nc",
    restart   = "results/PISM_file/test_glacialindex_GRN_20km.nc",
  resources:
    nodes = 1,
    partition = "standard96:test",
    time = "1:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    start = 0,
    stop = 10,
    ts_times = 1,
    ex_times = 1,
  output:
    main = "results/PISM_results/test_multirun/multirun_0_10.nc",
    ex   = "results/PISM_results/test_multirun/ex_multirun_0_10.nc",
    ts   = "results/PISM_results/test_multirun/ts_multirun_0_10.nc",
  shell:
    assemble_cmd_options("GRN_20km", bootstrap=True, climate="index_forcing", ocean="th", use_spack=True)


rule test_multirun_2:
  input:
    restart = "results/PISM_results/test_multirun/multirun_0_10.nc",
    main    = "results/PISM_file/test_glacialindex_GRN_20km.nc",
  resources:
    nodes = 1,
    partition = "standard96:test",
    time = "1:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5,
    ts_times = 1,
    ex_times = 1,

  output:
    main = "results/PISM_results/test_multirun/multirun_10_15.nc",
    ex   = "results/PISM_results/test_multirun/ex_multirun_10_15.nc",
    ts   = "results/PISM_results/test_multirun/ts_multirun_10_15.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="index_forcing", time="duration", ocean="th", use_spack=True)

rule test_multirun_3:
  input:
    main    = "results/PISM_file/test_glacialindex_GRN_20km.nc",
    restart = "results/PISM_results/test_multirun/multirun_10_15.nc",
  resources:
    nodes = 1,
    partition = "standard96:test",
    time = "1:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5,
    ts_times = 1,
    ex_times = 1,

  output:
    main = "results/PISM_results/test_multirun/multirun_15_20.nc",
    ex   = "results/PISM_results/test_multirun/ex_multirun_15_20.nc",
    ts   = "results/PISM_results/test_multirun/ts_multirun_15_20.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="index_forcing", time="duration", ocean="th", use_spack=True)



rule gi_heinrich_first:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_GRN_20km.nc",
    restart   = "results/PISM_file/glacialindex_tillphi_GRN_20km.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 1,
    partition = "standard96:test",
    time = "1:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    start = -120000,
    stop = -119000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_0_10.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_0_10.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_0_10.nc",
  shell:
    assemble_cmd_options("GRN_20km", bootstrap=True, climate="index_forcing", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_2:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_GRN_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_0_10.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 1,
    partition = "standard96:test",
    time = "1:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 1000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-119000-118000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-119000-118000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-119000-118000.nc",
  shell:
    assemble_cmd_options("GRN_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)
