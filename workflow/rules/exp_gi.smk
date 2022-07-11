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
        "-geometry.ice_free_thickness_standard 10",
        "-grid.registration corner",
        "-z_spacing equal",
        "-energy.enthalpy.temperate_ice_thermal_conductivity_ratio 0.01",
        "-energy.basal_melt.use_grounded_cell_fraction False",
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
        "-thickness_calving_threshold 200",
        "-calving.eigen_calving.K 1.e+17",
        ]
    extra_vars = {
        "standard": ["-extra_vars topg,thk,mask,velsurf_mag,velsurf,velbase_mag,tillwat,tauc,temppabase,climatic_mass_balance,effective_precipitation,effective_air_temp"],
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
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    start = -120000,
    stop = -115000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-120000_-115000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-120000_-115000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-120000_-115000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=True, climate="index_forcing", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_02:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-120000_-115000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-115000_-110000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-115000_-110000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-115000_-110000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_03:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-115000_-110000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-110000_-105000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-110000_-105000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-110000_-105000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_04:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-110000_-105000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-105000_-100000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-105000_-100000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-105000_-100000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_05:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-105000_-100000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-100000_-95000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-100000_-95000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-100000_-95000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_06:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-100000_-95000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-95000_-90000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-95000_-90000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-95000_-90000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_07:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-95000_-90000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-90000_-85000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-90000_-85000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-90000_-85000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_08:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-90000_-85000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-85000_-80000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-85000_-80000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-85000_-80000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_09:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-85000_-80000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-80000_-75000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-80000_-75000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-80000_-75000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_10:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-80000_-75000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-75000_-70000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-75000_-70000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-75000_-70000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_11:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-75000_-70000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-70000_-65000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-70000_-65000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-70000_-65000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_12:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-70000_-65000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-65000_-60000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-65000_-60000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-65000_-60000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_13:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-65000_-60000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 9,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-60000_-55000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-60000_-55000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-60000_-55000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_14:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-60000_-55000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-55000_-50000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-55000_-50000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-55000_-50000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_15:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-55000_-50000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-50000_-45000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-50000_-45000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-50000_-45000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_16:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-50000_-45000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-45000_-40000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-45000_-40000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-45000_-40000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_17:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-45000_-40000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-40000_-35000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-40000_-35000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-40000_-35000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_18:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-40000_-35000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-35000_-30000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-35000_-30000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-35000_-30000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_19:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-35000_-30000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-30000_-25000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-30000_-25000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-30000_-25000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_20:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-30000_-25000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-25000_-20000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-25000_-20000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-25000_-20000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_21:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-25000_-20000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-20000_-15000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-20000_-15000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-20000_-15000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_22:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-20000_-15000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-15000_-10000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-15000_-10000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-15000_-10000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_23:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-15000_-10000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-10000_-5000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-10000_-5000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-10000_-5000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)

rule gi_heinrich_24:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_heinrich/gi_heinrich_-10000_-5000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    spackpackage = "pism-sbeyer@current",
    duration = 5000,
    ts_times = 10,
    ex_times = 100,
  output:
    main = "results/PISM_results_large/gi_heinrich/gi_heinrich_-5000_-0000.nc",
    ex   = "results/PISM_results_large/gi_heinrich/ex_gi_heinrich_-5000_-0000.nc",
    ts   = "results/PISM_results_large/gi_heinrich/ts_gi_heinrich_-5000_-0000.nc",
  shell:
    assemble_cmd_options("NHEM_20km", bootstrap=False, climate="index_forcing", time="duration", ocean="th", do_sealevel=True, do_bed_deformation=True, use_spack=True)
