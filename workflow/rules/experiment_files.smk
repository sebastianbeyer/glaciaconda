rule pismtest:
  input:
      "results/PISM_file/test_NHEM_20km.nc",
      "results/PISM_file/test_NHEM_20km_tillphi.nc",
      expand("results/PISM_file/heinrich_tillphi_taufac{factor}_NHEM_20km.nc", factor=[0.006, 0.008, 0.01, 0.0125, 0.016, 0.02, 0.024, 0.028, 0.03, 0.035, 0.04, 0.06, 0.08, 0.1  ]),

rule greenland_yearmean:
  input:
    "results/PISM_file/greenland_PD_GRN_20km_yearmean.nc",
    "results/PISM_file/greenland_PD_GRN_20km.nc",


rule assembled_model:
    input:
        atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ICE7GNA/ICE7GNA_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
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

rule assembled_model_glacialindex:
    input:
        index     = "results/glacialindex/glacialindex.nc",
        atmo1     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean1    = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        atmo0     = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_atmo.nc",
        ocean0    = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ICE7GNA/ICE7GNA_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
        refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
    output:
        main      = "results/PISM_file/glacialindex_{grid_name}.nc",
    shell:
        """

        # convert to netcdf3 because in 4 the renaming of dimensions does not
        # work
        ncks -3 {input.atmo0} tmp_atmo0_netcdf3.nc
        ncrename -v time,time_periodic \
                 -v time_bnds,time_bnds_periodic \
                 -v air_temp,airtemp_0 \
                 -v precipitation,precip_0 \
                 -v air_temp_sd,airtempsd_0 \
                 -d time,time_periodic \
                 tmp_atmo0_netcdf3.nc atmo0_tmp.nc
        ncks --fix_rec_dmn time_periodic atmo0_tmp.nc atmo0_tmp2.nc

        ncks -3 {input.atmo1} tmp_atmo1_netcdf3.nc
        ncrename -v time,time_periodic \
                 -v time_bnds,time_bnds_periodic \
                 -v air_temp,airtemp_1 \
                 -v precipitation,precip_1 \
                 -v air_temp_sd,airtempsd_1 \
                 -d time,time_periodic \
                 tmp_atmo1_netcdf3.nc atmo1_tmp.nc
        ncks --fix_rec_dmn time_periodic atmo1_tmp.nc atmo1_tmp2.nc


        ncks atmo0_tmp2.nc {output.main}
        ncks -A atmo1_tmp2.nc {output.main}

        rm tmp_atmo0_netcdf3.nc atmo0_tmp.nc atmo0_tmp2.nc
        rm tmp_atmo1_netcdf3.nc atmo1_tmp.nc atmo1_tmp2.nc


        # currently no index for the ocean is possible, so just use present day
        ncks -3 {input.ocean0} tmp_ocean0_netcdf3.nc
        ncrename -v time,time_periodic \
                 -v time_bnds,time_bnds_periodic \
                 -d time,time_periodic \
                 tmp_ocean0_netcdf3.nc ocean0_tmp.nc
        ncks --fix_rec_dmn time_periodic ocean0_tmp.nc ocean0_tmp2.nc
        ncks -A ocean0_tmp2.nc {output.main}

        rm tmp_ocean0_netcdf3.nc ocean0_tmp.nc ocean0_tmp2.nc

        ncks -A {input.index} {output.main}

        ncks -A {input.heatflux} {output.main}
        ncks -A -v topg {input.topg} {output.main}
        ncks -A -v thk {input.thk} {output.main}
        ncks -A {input.oceankill} {output.main}

        # make time use time bounds periodic
        ncatted -O -a bounds,time_periodic,o,c,"time_bnds_periodic" {output.main}

        ncatted -a _FillValue,glac_index,d,, {output.main}
        ncatted -a _FillValue,time_bnds,d,, {output.main}

        # delete history
        ncatted -a history,global,d,, {output.main}
        ncatted -a history_of_appended_files,global,d,, {output.main}

        """

rule assembled_model_glacialindex_fake:
    input:
        index     = "results/glacialindex/test_glacialindex.nc",
        atmo1     = "results/CESM/LGM_NOVEG/LGM_NOVEG_GRN_20km_atmo.nc",
        ocean1    = "results/CESM/LGM_NOVEG/LGM_NOVEG_GRN_20km_ocean.nc",
        atmo0     = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_GRN_20km_atmo.nc",
        ocean0    = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_GRN_20km_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_GRN_20km.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_GRN_20km.nc",
        thk       = "results/topography/ICE7GNA/ICE7GNA_GRN_20km.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_GRN_20km.nc",
        refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_GRN_20km_refHeight.nc",
    output:
        main      = "results/PISM_file/test_glacialindex_GRN_20km.nc",
    shell:
        """

        # convert to netcdf3 because in 4 the renaming of dimensions does not
        # work
        ncks -3 {input.atmo0} tmp_atmo0_netcdf3.nc
        ncrename -v time,time_periodic \
                 -v time_bnds,time_bnds_periodic \
                 -v air_temp,airtemp_0 \
                 -v precipitation,precip_0 \
                 -v air_temp_sd,airtempsd_0 \
                 -d time,time_periodic \
                 tmp_atmo0_netcdf3.nc atmo0_tmp.nc
        ncks --fix_rec_dmn time_periodic atmo0_tmp.nc atmo0_tmp2.nc


        ncks -3 {input.atmo1} tmp_atmo1_netcdf3.nc
        ncrename -v time,time_periodic \
                 -v time_bnds,time_bnds_periodic \
                 -v air_temp,airtemp_1 \
                 -v precipitation,precip_1 \
                 -v air_temp_sd,airtempsd_1 \
                 -d time,time_periodic \
                 tmp_atmo1_netcdf3.nc atmo1_tmp.nc
        ncks --fix_rec_dmn time_periodic atmo1_tmp.nc atmo1_tmp2.nc


        ncks atmo0_tmp2.nc {output.main}
        ncks -A atmo1_tmp2.nc {output.main}

        rm tmp_atmo0_netcdf3.nc atmo0_tmp.nc atmo0_tmp2.nc
        rm tmp_atmo1_netcdf3.nc atmo1_tmp.nc atmo1_tmp2.nc


        # currently no index for the ocean is possible, so just use present day
        ncks -3 {input.ocean0} tmp_ocean0_netcdf3.nc
        ncrename -v time,time_periodic \
                 -v time_bnds,time_bnds_periodic \
                 -d time,time_periodic \
                 tmp_ocean0_netcdf3.nc ocean0_tmp.nc
        ncks --fix_rec_dmn time_periodic ocean0_tmp.nc ocean0_tmp2.nc
        ncks -A ocean0_tmp2.nc {output.main}

        rm tmp_ocean0_netcdf3.nc ocean0_tmp.nc ocean0_tmp2.nc



        ncks -A {input.index} {output.main}

        ncks -A {input.heatflux} {output.main}
        ncks -A -v topg {input.topg} {output.main}
        ncks -A -v thk {input.thk} {output.main}
        ncks -A {input.oceankill} {output.main}

        # make time use time bounds periodic
        ncatted -O -a bounds,time_periodic,o,c,"time_bnds_periodic" {output.main}

        ncatted -a _FillValue,glac_index,d,, {output.main}
        ncatted -a _FillValue,time_bnds,d,, {output.main}

        # delete history
        ncatted -a history,global,d,, {output.main}
        ncatted -a history_of_appended_files,global,d,, {output.main}

        # replace all the values in the files with fake  values to test PISM GI
        # code
        ncap2 -s "where(airtemp_0<10000) airtemp_0=200" {output.main} tmp_replace.nc
        ncap2 -s "where(airtemp_1<10000) airtemp_1=300" tmp_replace.nc {output.main}
        """

rule modelfile_greenland_PD_yearmean:
    input:
        atmo      = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_atmo_yearmean.nc",
        ocean     = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_ocean_yearmean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
        refheight = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_refHeight.nc",
    output:
        main      = "results/PISM_file/greenland_PD_{grid_name}_yearmean.nc",
        refheight = "results/PISM_file/greenland_PD_{grid_name}_yearmean_refheight.nc",
    shell:
        """
        ncks {input.atmo} {output.main}
        ncks -A {input.ocean} {output.main}
        ncks -A -v bheatflx {input.heatflux} {output.main}
        ncks -A -v topg {input.topg} {output.main}
        ncks -A -v thk {input.thk} {output.main}
        ncks -A {input.oceankill} {output.main}

        cp {input.refheight} {output.refheight}
        """

rule modelfile_greenland_PD_monthly:
    input:
        atmo      = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_atmo.nc",
        ocean     = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
        refheight = "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_{grid_name}_refHeight.nc",
    output:
        main      = "results/PISM_file/greenland_PD_{grid_name}.nc",
        refheight = "results/PISM_file/greenland_PD_{grid_name}_refheight.nc",
    shell:
        """
        ncks {input.atmo} {output.main}
        ncks -A {input.ocean} {output.main}
        ncks -A -v bheatflx {input.heatflux} {output.main}
        ncks -A -v topg {input.topg} {output.main}
        ncks -A -v thk {input.thk} {output.main}
        ncks -A {input.oceankill} {output.main}

        # delete history
        ncatted -a history,global,d,, {output.main}
        ncatted -a history_of_appended_files,global,d,, {output.main}

        cp {input.refheight} {output.refheight}
        """

rule assembled_model_tillphi:
    input:
        atmo      = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_atmo.nc",
        ocean     = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_ocean.nc",
        heatflux  = "results/heatflux/shapiro/shapiro_{grid_name}.nc",
        topg      = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
        thk       = "results/topography/ICE7GNA/ICE7GNA_{grid_name}.nc",
        oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
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
    thk       = "results/topography/ICE7GNA/ICE7GNA_{grid_name}.nc",
    oceankill = "results/oceankill/oceankill_ETOPO1_{grid_name}.nc",
    refheight = "results/CESM/LGM_NOVEG/LGM_NOVEG_{grid_name}_refHeight.nc",
    tillphi   = "results/sediment/tillphi/tillphi_LaskeMasters_taufac{factor}_{grid_name}.nc"
  output:
    #main      = expand("results/PISM_file/heinrich_taufac{factor}_NHEM_20km.nc", factor=[0.006, 0.008, 0.01, 0.0125, 0.02, 0.04, 0.1  ]),
    main      = "results/PISM_file/heinrich_tillphi_taufac{factor}_{grid_name}.nc",
    refheight = "results/PISM_file/heinrich_tillphi_taufac{factor}_{grid_name}_refheight.nc",

