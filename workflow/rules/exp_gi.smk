

rule gi_heinrich_first:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-120000_-115000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-120000_-115000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-120000_-115000.nc",
  resources:
    nodes = config['default_resources_large']['nodes'],
    partition = config['default_resources_large']['partition'],
    time = config['default_resources_large']['time'],
  params:
    start = -120000,
    stop =  -115000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load pism-sbeyer@current \n \nsrun pismr" if config['use_spack'] else config['header_local'],
    climate = get_climate_indexforcing_from_parameters,
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
-bed_def lc \\
-sea_level constant,delta_sl \\
-ocean_delta_sl_file {input.sealevel} \\
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

rule gi_heinrich_02:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-120000_-115000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-115000_-110000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi{paramset}_-115000_-110000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi{paramset}_-115000_-110000.nc",
  resources:
    nodes = config['default_resources_large']['nodes'],
    partition = config['default_resources_large']['partition'],
    time = config['default_resources_large']['time'],
  params:
    duration = 5000,
    ts_times = config['times']['ts_times'],
    ex_times = config['times']['ex_times'],
    header = lambda wildcards: "spack load pism-sbeyer@current \n \n srun pismr" if config['use_spack'] else config['header_local'],
    climate = get_climate_indexforcing_from_parameters,
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
-ocean.th.periodic True \\
-atmosphere.given.periodic True \\
-surface.pdd.std_dev.periodic True \\
-i {input.restart} \\
-o {output.main} \\
-ts_file {output.ts} \\
-extra_file {output.ex} \\
-y {params.duration} \\
-ts_times {params.ts_times} \\
-extra_times {params.ex_times} \\
-front_retreat_file {input.main} \\
-bed_def lc \\
-sea_level constant,delta_sl \\
-ocean_delta_sl_file {input.sealevel} \\
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

use rule gi_heinrich_02 as gi_heinrich_03 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-115000_-110000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-110000_-105000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-110000_-105000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-110000_-105000.nc",

use rule gi_heinrich_02 as gi_heinrich_04 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-110000_-105000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-105000_-100000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-105000_-100000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-105000_-100000.nc",

use rule gi_heinrich_02 as gi_heinrich_05 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-105000_-100000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-100000_-95000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-100000_-95000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-100000_-95000.nc",

use rule gi_heinrich_02 as gi_heinrich_06 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-100000_-95000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-95000_-90000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-95000_-90000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-95000_-90000.nc",

use rule gi_heinrich_02 as gi_heinrich_07 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-95000_-90000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-90000_-85000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-90000_-85000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-90000_-85000.nc",

use rule gi_heinrich_02 as gi_heinrich_08 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-90000_-85000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-85000_-80000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-85000_-80000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-85000_-80000.nc",

use rule gi_heinrich_02 as gi_heinrich_09 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-85000_-80000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-80000_-75000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-80000_-75000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-80000_-75000.nc",

use rule gi_heinrich_02 as gi_heinrich_10 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-80000_-75000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-75000_-70000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-75000_-70000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-75000_-70000.nc",

use rule gi_heinrich_02 as gi_heinrich_11 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-75000_-70000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-70000_-65000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-70000_-65000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-70000_-65000.nc",

use rule gi_heinrich_02 as gi_heinrich_12 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-70000_-65000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-65000_-60000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-65000_-60000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-65000_-60000.nc",

use rule gi_heinrich_02 as gi_heinrich_13 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-65000_-60000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-60000_-55000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-60000_-55000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-60000_-55000.nc",

use rule gi_heinrich_02 as gi_heinrich_14 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-60000_-55000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-55000_-50000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-55000_-50000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-55000_-50000.nc",

use rule gi_heinrich_02 as gi_heinrich_15 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-55000_-50000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-50000_-45000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-50000_-45000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-50000_-45000.nc",

use rule gi_heinrich_02 as gi_heinrich_16 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-50000_-45000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-45000_-40000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-45000_-40000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-45000_-40000.nc",

use rule gi_heinrich_02 as gi_heinrich_17 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-45000_-40000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-40000_-35000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-40000_-35000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-40000_-35000.nc",

use rule gi_heinrich_02 as gi_heinrich_18 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-40000_-35000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-35000_-30000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-35000_-30000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-35000_-30000.nc",

use rule gi_heinrich_02 as gi_heinrich_19 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-35000_-30000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-30000_-25000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-30000_-25000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-30000_-25000.nc",

use rule gi_heinrich_02 as gi_heinrich_20 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-30000_-25000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-25000_-20000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-25000_-20000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-25000_-20000.nc",

use rule gi_heinrich_02 as gi_heinrich_21 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-25000_-20000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-20000_-15000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-20000_-15000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-20000_-15000.nc",

use rule gi_heinrich_02 as gi_heinrich_22 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-20000_-15000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-15000_-10000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-15000_-10000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-15000_-10000.nc",

use rule gi_heinrich_02 as gi_heinrich_23 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-15000_-10000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-10000_-5000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-10000_-5000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-10000_-5000.nc",

use rule gi_heinrich_02 as gi_heinrich_24 with:
  input:
    main      = "results/PISM_file/glacialindex_tillphi_NHEM_20km.nc",
    restart   = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-10000_-5000.nc",
    sealevel  = "datasets/sealevel/pism_dSL_Imbrie2006.nc"
  output:
    main = "results/PISM_results_large/gi_{paramset}/gi_{paramset}_-5000_-0000.nc",
    ex   = "results/PISM_results_large/gi_{paramset}/ex_gi_{paramset}_-5000_-0000.nc",
    ts   = "results/PISM_results_large/gi_{paramset}/ts_gi_{paramset}_-5000_-0000.nc",
