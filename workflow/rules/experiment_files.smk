rule pismtest:
    input:
      "results/PISM_file/test_NHEM_20km.nc",
      "results/PISM_file/test_NHEM_20km_tillphi.nc",
      expand("results/PISM_file/heinrich_tillphi_taufac{factor}_NHEM_20km.nc", factor=[0.006, 0.008, 0.01, 0.0125, 0.02, 0.04, 0.1  ]),


rule assembled_model:
    input:
        atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ICE7GNA_{grid_name}.nc",
        refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
    output:
        main      = "results/PISM_file/test_{grid_name}.nc",
        refheight = "results/PISM_file/test_{grid_name}_refheight.nc",
    shell:
        """
        ncks {input.atmo} {output.main}
        ncks -A {input.ocean} {output.main}
        ncks -A {input.heatflux} {output.main}
        ncks -A -v topg {input.topg} {output.main}
        ncks -A -v thk {input.thk} {output.main}
        ncks -A {input.oceankill} {output.main}

        cp {input.refheight} {output.refheight}
        """

rule assembled_model_tillphi:
    input:
        atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ICE7GNA_{grid_name}.nc",
        refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
        tillphi   = "results/sediment/tillphi/tillphi_LaskeMasters_{grid_name}.nc"
    output:
        main      = "results/PISM_file/test_{grid_name}_tillphi.nc",
        refheight = "results/PISM_file/test_{grid_name}_tillphi_refheight.nc",
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

# note that you must redefine all components of input when you inherit from it.
# not just the one you are changing!
use rule assembled_model_tillphi as heinrich_factor with:
  input:
    atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
    ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
    heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
    topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
    thk       = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
    oceankill = "results/oceankill/oceankill_ICE7GNA_{grid_name}.nc",
    refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
    tillphi   = "results/sediment/tillphi/tillphi_LaskeMasters_taufac{factor}_{grid_name}.nc"
  output:
    #main      = expand("results/PISM_file/heinrich_taufac{factor}_NHEM_20km.nc", factor=[0.006, 0.008, 0.01, 0.0125, 0.02, 0.04, 0.1  ]),
    main      = "results/PISM_file/heinrich_tillphi_taufac{factor}_{grid_name}.nc",
    refheight = "results/PISM_file/heinrich_tillphi_taufac{factor}_{grid_name}_refheight.nc",

