
rule MillenialScaleOscillations_clim_dT:
  input:
    main      = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km.nc",
    refheight = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_refheight.nc",
    delta_t   = "results/PISM_file/MillenialScaleOscillations_climatology_NHEM_20km_delta_T.nc",
  output:
    main = "results/PISM_results_large/MSO_clim_dT_{paramset}/MSO_clim_dT_{paramset}.nc",
    ex   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ex_MSO_clim_dT_{paramset}.nc",
    ts   = "results/PISM_results_large/MSO_clim_dT_{paramset}/ts_MSO_clim_dT_{paramset}.nc",
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
-ocean.th.periodic True \\
-atmosphere.given.periodic True \\
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
-ocean th \\
-ocean_th_file {input.main} \\
{params.grid} \\
{params.extra_vars} \\
{params.climate} \\
{params.dynamics} \\
{params.calving} \\
{params.always_on} \\
{params.marine_ice_sheets} \\

    """
