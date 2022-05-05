# rule GI_heinrich:
#  input:
#    atmo = "results/CESM/glacialindex_offline/CESM_GI.nc",
#    refheight = "results/CESM/glacialindex_offline/CESM_GI_refheight.nc",
#    ocean = "results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_ocean.nc",
#    heatflux = ""
#    topography = ""
#    # todo: initialice
#    oceankill = ""

rule frankenstein_GI_heinrich:
  input:
    #old = "/home/sebi/Nextcloud/palmod/datasets/automaticIceData/output/CESM_35ka_LaskeMasters_NHEM20km/CESM_LGM_LaskeMasters_NHEM20km_4PISM_.nc",
    old = "/home/sebi/Nextcloud/palmod/datasets/automaticIceData/output/CESM_35ka_LaskeMasters_NHEM20km/CESM_35ka_LaskeMasters_NHEM20km_4PISM_.nc",
    newgi = "results/CESM/glacialindex_offline/CESM_GI.nc",
    refheight = "results/CESM/glacialindex_offline/CESM_GI_refheight.nc",
  output:
    main = "results/CESM/glacialindex_offline/CESM_GI_frankenstein.nc",
  shell:
    """
    ncks -O -v lat,lat_bnds,lon,lon_bnds,x,y,bheatflx,topg,thk,land_ice_area_fraction_retreat,tillphi {input.old} tmpfile.nc
    # ncks -O -v lat,lat_bnds,lon,lon_bnds,x,y,salinity_ocean,theta_ocean,bheatflx,topg,thk,land_ice_area_fraction_retreat,tillphi {input.old} tmpfile.nc
    cdo -O merge tmpfile.nc {input.newgi} {output.main}
    """



