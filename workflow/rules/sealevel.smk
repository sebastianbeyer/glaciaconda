
# don't use it for now
#rule sealevel_imbrie2006:
#    output:
#        "datasets/sealevel/pism_dSL_Imbrie2006.nc",
#    shell:
#      """
#      workflow/scripts/download_datasets/download_sealevel.sh {output}
#      """

rule sealevel_sprack_lisiecki:
    output:
        "datasets/sealevel/sealevel_sprack_lisiecki_2016.txt",
    shell:
        """
        wget -O {output} https://www.ncei.noaa.gov/pub/data/paleo/contributions_by_author/spratt2016/spratt2016.txt
        """
