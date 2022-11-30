rule all_mso:
    input: 

def get_time_for_attempt(wildcards, attempt):
    # if this is not the first attempt use full 12 hours of runtime
    if attempt == 1:
        return "6:00:00"
    if attempt > 1:
        return "12:00:00"

def get_max_dt_for_attempt(wildcards, attempt):
    if attempt == 1:
        return "1year"
    if attempt == 2:
        return "1month"
    if attempt == 3:
        return "1week"

def get_dT_forcingfile(wildcards):
    delta_t        = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_NHEM_20km_delta_T_smooth_300.nc",
    delta_t_ctrl   = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_NHEM_20km_delta_T_control.nc",
    if wildcards.forcing == "base":
        return delta_t
    if wildcards.forcing == "ctrl":
        return delta_t_ctrl

def get_dP_forcingfile(wildcards):
    delta_P        = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_NHEM_20km_delta_P_smooth_300.nc",
    delta_P_ctrl   = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_NHEM_20km_delta_P_control.nc",
    if wildcards.forcing == "base":
        return delta_P
    if wildcards.forcing == "ctrl":
        return delta_P_ctrl

rule MillenialScaleOscillations_clim_dT:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
  output:
    main =    "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-50000_-45000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-50000_-45000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-50000_-45000.nc",
  retries: 3
  resources:
    nodes = 8,
    partition = "standard96",
    time = get_time_for_attempt,
    max_dt = get_max_dt_for_attempt,
  params:
    start = -50000,
    stop =  -45000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = "spack load pism@2.0.5 \n \nsrun pismr",
    climate = get_climate_pdd_deltaT_from_parameters,
    dynamics = get_dynamics_from_parameters,
    calving = get_calving_from_parameters,
    always_on = get_always_on_parameters,
    marine_ice_sheets = get_PISM_marine_ice_sheets_parameters,
    extra_vars = config['PISM_extra_vars'],
    grid = config['PISM_grids']['NHEM_20km'],
  shell:
    """
{params.header} \\
-time_stepping.maximum_time_step {resources.max_dt} \\
-bootstrap True \\
-atmosphere.given.periodic True \\
-atmosphere.file {input.main} \\
-surface.pdd.std_dev.periodic True \\
-i {input.main} \\
-o {output.main} \\
-ts_file {output.ts} \\
-extra_file {output.ex} \\
-ys {params.start} \\
-ye {params.stop} \\
-ts_times {params.ts_times} \\
-extra_times {params.ex_times} \\
-front_retreat_file {input.main} \\
-ocean pik \\
{params.grid} \\
{params.extra_vars} \\
{params.climate} \\
{params.dynamics} \\
{params.calving} \\
{params.always_on} \\
{params.marine_ice_sheets} \\

    """

rule MillenialScaleOscillations_clim_dT_2:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-50000_-45000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-45000_-40000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-45000_-40000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-45000_-40000.nc",
  retries: 3
  resources:
    nodes = 8,
    partition = "standard96",
    time = get_time_for_attempt,
    max_dt = get_max_dt_for_attempt,
  params:
    duration = 5000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = "spack load pism@2.0.5 \n \nsrun pismr",
    climate = get_climate_pdd_deltaT_from_parameters,
    dynamics = get_dynamics_from_parameters,
    calving = get_calving_from_parameters,
    always_on = get_always_on_parameters,
    marine_ice_sheets = get_PISM_marine_ice_sheets_parameters,
    extra_vars = config['PISM_extra_vars'],
    grid = config['PISM_grids']['NHEM_20km'],
  shell:
    """
{params.header} \\
-time_stepping.maximum_time_step {resources.max_dt} \\
-bootstrap False \\
-atmosphere.given.periodic True \\
-atmosphere.given.file {input.main} \\
-surface.pdd.std_dev.periodic True \\
-i {input.restart} \\
-o {output.main} \\
-ts_file {output.ts} \\
-extra_file {output.ex} \\
-y {params.duration} \\
-ts_times {params.ts_times} \\
-extra_times {params.ex_times} \\
-front_retreat_file {input.main} \\
-ocean pik \\
{params.grid} \\
{params.extra_vars} \\
{params.climate} \\
{params.dynamics} \\
{params.calving} \\
{params.always_on} \\
{params.marine_ice_sheets} \\

    """


use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_3 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-45000_-40000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-40000_-35000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-40000_-35000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-40000_-35000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_4 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-40000_-35000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-35000_-30000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-35000_-30000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-35000_-30000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_5 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-35000_-30000.nc",
  output:
    main =    "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-30000_-25000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-30000_-25000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-30000_-25000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_6 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-30000_-25000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-25000_-20000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-25000_-20000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-25000_-20000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_7 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-25000_-20000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-20000_-15000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-20000_-15000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-20000_-15000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_8 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-20000_-15000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-15000_-10000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-15000_-10000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-15000_-10000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_9 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-15000_-10000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-10000_-05000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-10000_-05000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-10000_-05000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_10 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-10000_-05000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-05000_-00000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-05000_-00000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-05000_-00000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_11 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-05000_-00000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_00000_05000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_00000_05000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_00000_05000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_12 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_00000_05000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_05000_10000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_05000_10000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_05000_10000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_13 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_05000_10000.nc",
  output:
    main =    "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_10000_15000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_10000_15000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_10000_15000.nc",

use rule MillenialScaleOscillations_clim_dT_2 as MillenialScaleOscillations_clim_dT_14 with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = get_dT_forcingfile,
    delta_p   = get_dP_forcingfile,
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_10000_15000.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_15000_20000.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_15000_20000.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_15000_20000.nc",


rule merge_mso_clim:
    input:
        "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-50000_-45000.nc",
        "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-45000_-40000.nc",
        "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-40000_-35000.nc",
    output:
        "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_{forcing}_NHEM_20km_-50000_20000.nc",
    conda:
        "../envs/dataprep.yaml",
    shell:
        """
        cdo -O mergetime {input} {output}
        """
