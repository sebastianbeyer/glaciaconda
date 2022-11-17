
rule MillenialScaleOscillations_clim_dT:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_NHEM_20km.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_NHEM_20km.nc",
  resources:
    nodes = config['default_resources_large']['nodes'],
    partition = config['default_resources_large']['partition'],
    time = config['default_resources_large']['time'],
  params:
    start = -50000,
    stop =  0,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load pism-sbeyer@current \n \nsrun pismr" if config['use_spack'] else config['header_local'],
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

rule MillenialScaleOscillations_clim_dT_continue:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km_continue.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_NHEM_20km_continue.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_NHEM_20km_continue.nc",
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    duration = 12000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load pism-sbeyer@current \n \nsrun pismr" if config['use_spack'] else config['header_local'],
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


rule MillenialScaleOscillations_clim_dT_continue_more:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km_continue.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km_continue_more.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_NHEM_20km_continue_more.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_NHEM_20km_continue_more.nc",
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    duration = 40000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load /nn3hubrk \n \nsrun pismr" if config['use_spack'] else config['header_local'],
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

rule MillenialScaleOscillations_clim_dT_continue_more_nodebug:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km_continue.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}_NHEM_20km_continue_more_nodebug.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}_NHEM_20km_continue_more_nodebug.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}_NHEM_20km_continue_more_nodebug.nc",
  resources:
    nodes = 8,
    partition = "standard96",
    time = "12:00:00",
  params:
    duration = 40000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load /aukaa6i6 \n \nsrun pismr" if config['use_spack'] else config['header_local'],
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

########################
## control runs

rule MillenialScaleOscillations_clim_dT_ctrl:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_NHEM_20km_delta_T_control.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_ctrl_{paramset}_NHEM_20km.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_ctrl_{paramset}_NHEM_20km.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_ctrl_{paramset}_NHEM_20km.nc",
  resources:
    nodes = config['default_resources_large']['nodes'],
    partition = config['default_resources_large']['partition'],
    time = "6:00:00",
  params:
    start = -50000,
    stop =  -30000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load pism-sbeyer@current \n \nsrun pismr" if config['use_spack'] else config['header_local'],
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


use rule MillenialScaleOscillations_clim_dT_continue as MillenialScaleOscillations_clim_dT_ctrl_continue with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_ctrl_{paramset}_NHEM_20km.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue.nc",

use rule MillenialScaleOscillations_clim_dT_continue_more as MillenialScaleOscillations_clim_dT_ctrl_continue_more with:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
    restart   = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue_more.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue_more.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_ctrl_{paramset}_NHEM_20km_continue_more.nc",
