
rule assembled_model_simple_heinrich:
    input:
        atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/GLAC1D/GLAC1D_nn9927_NaGrB_-21000k_thk_NHEM_20km.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
        tillphi   = "results/sediment/tillphi/tillphi_LaskeMasters_taufac0.01_{grid_name}.nc"
    output:
        main      = "results/PISM_file/LGM_simple_heinrich_{grid_name}.nc",
        refheight = "results/PISM_file/LGM_simple_heinrich_{grid_name}_refheight.nc",
    conda:
        "../envs/dataprep.yaml",

    shell:
        """
        ncks {input.atmo} {output.main}
        ncks -A {input.ocean} {output.main}
        ncks -A {input.heatflux} {output.main}
        ncks -A -v topg {input.topg} {output.main}
        ncks -A -v thk {input.thk} {output.main}
        ncks -A {input.oceankill} {output.main}
        ncks -A {input.tillphi} {output.main}

        cp {input.refheight} {output.refheight}
        """

rule heinrich_simple:
  input:
    main      = "results/PISM_file/LGM_simple_heinrich_{grid_name}.nc",
    refheight = "results/PISM_file/LGM_simple_heinrich_{grid_name}_refheight.nc",
  output:
    main = "results/PISM_results_large/LGM_simple_heinrich_{paramset}/LGM_simple_heinrich_{paramset}_{grid_name}.nc",
    ex   = "results/PISM_results_large/LGM_simple_heinrich_{paramset}/ex_LGM_simple_heinrich_{paramset}_{grid_name}.nc",
    ts   = "results/PISM_results_large/LGM_simple_heinrich_{paramset}/ts_LGM_simple_heinrich_{paramset}_{grid_name}.nc",
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
    climate = get_climate_pdd_from_parameters,
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
-ocean.th.periodic True \\
-ocean_th_file {input.main}
{params.grid} \\
{params.extra_vars} \\
{params.climate} \\
{params.dynamics} \\
{params.calving} \\
{params.always_on} \\
{params.marine_ice_sheets} \\

    """
