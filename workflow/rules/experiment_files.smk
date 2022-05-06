rule pismtest:
    input:
      "results/PISM_file/test_NHEM_20km.nc",

rule assembled_model:
    input:
        atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ICE7GNA_NHEM_20km.nc",
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
        oceankill = "results/oceankill/oceankill_ICE7GNA_NHEM_20km.nc",
        refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
        tillphi   = "results/sediment/tillphi/tillphi_LaskeMasters_NHEM_20km.nc"
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
