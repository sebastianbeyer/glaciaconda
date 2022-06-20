

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
            "-atmosphere_index_file {params.indexfile}",
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
          "-extra_times 1",
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



rule test_multirun_first:
  input:
    main      = "results/PISM_file/test_glacialindex_GRN_20km.nc",
  params:
    spackpackage = "pism-sbeyer@master",
    start = 0,
    stop = 10,
    indexfile = "results/PISM_file/test_glacialindex_GRN_20km.nc",
  output:
    main = "results/PISM_results/test_multirun/multirun_0_10.nc",
    ex   = "results/PISM_results/test_multirun/ex_multirun_0_10.nc",
    ts   = "results/PISM_results/test_multirun/ts_multirun_0_10.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="index_forcing", ocean="th", use_spack=False)


rule test_multirun_2:
  input:
    main      = "results/PISM_results/test_multirun/multirun_0_10.nc",
  params:
    spackpackage = "pism-sbeyer@master",
    duration = 5,
    indexfile = "results/PISM_file/test_glacialindex_GRN_20km.nc",
   
  output:
    main = "results/PISM_results/test_multirun/multirun_10_15.nc",
    ex   = "results/PISM_results/test_multirun/ex_multirun_10_15.nc",
    ts   = "results/PISM_results/test_multirun/ts_multirun_10_15.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="index_forcing", time="duration", ocean="th", use_spack=False)

rule test_multirun_3:
  input:
    main      = "results/PISM_results/test_multirun/multirun_10_15.nc",
  params:
    spackpackage = "pism-sbeyer@master",
    duration = 5,
    indexfile = "results/PISM_file/test_glacialindex_GRN_20km.nc",
   
  output:
    main = "results/PISM_results/test_multirun/multirun_15_20.nc",
    ex   = "results/PISM_results/test_multirun/ex_multirun_15_20.nc",
    ts   = "results/PISM_results/test_multirun/ts_multirun_15_20.nc",
  shell:
    assemble_cmd_options("GRN_20km", climate="index_forcing", time="duration", ocean="th", use_spack=False)
