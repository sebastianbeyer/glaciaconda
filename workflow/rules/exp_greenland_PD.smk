
rule Greenland_PD:
  input:
    main      = "results/PISM_file/CESM_PD_tillphi_GRN_20km.nc",
    refheight = "results/PISM_file/CESM_PD_tillphi_GRN_20km_refheight.nc",
  output:
    main = "results/PISM_results_large/Greenland_CESM_PD_{paramset}/Greenland_CESM_PD_{paramset}_GRN_20km.nc",
    ts =   "results/PISM_results_large/Greenland_CESM_PD_{paramset}/ts_Greenland_CESM_PD_{paramset}_GRN_20km.nc",
    ex =   "results/PISM_results_large/Greenland_CESM_PD_{paramset}/ex_Greenland_CESM_PD_{paramset}_GRN_20km.nc",
  resources:
    nodes = 8,
    partition = config['default_resources_large']['partition'],
    time = "6:00:00"
  params:
    start = -50000,
    stop =  0,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load pism@2.0.5 \n \nsrun pismr" if config['use_spack'] else config['header_local'],
    climate = get_climate_pdd_from_parameters,
    dynamics = get_dynamics_from_parameters,
    calving = get_calving_from_parameters,
    always_on = get_always_on_parameters,
    marine_ice_sheets = get_PISM_marine_ice_sheets_parameters,
    extra_vars = config['PISM_extra_vars'],
    grid = config['PISM_grids']['GRN_20km'],
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
