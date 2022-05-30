

rule sealevel_imbrie2006:
    output:
        "datasets/sealevel/pism_dSL_Imbrie2006.nc",
    shell:
      """
      workflow/scripts/download_datasets/download_sealevel.sh {output}
      """

