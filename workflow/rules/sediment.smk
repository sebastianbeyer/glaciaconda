

rule laskemasters:
    input:
        "results/sediment/LaskeMasters/LaskeMasters_NHEM_20km.nc",
        "results/sediment/tillphi/tillphi_LaskeMasters_NHEM_20km.nc",

rule sediment:
    conda: "../envs/base.yaml"
    resources:
        time = "00:10:00"
    input:
      sediment = "datasets/LaskeMasters/sedimentmap_Laske_Masters.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/sediment/LaskeMasters/LaskeMasters_{grid_name}.nc",
    shell:
      "python3 workflow/scripts/prepare_LaskeMasters.py {input.grid} {input.sediment} {output} "

rule tillphi:
    conda: "../envs/base.yaml"
    resources:
        time = "00:10:00"
    input:
      topg = "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
      sediment = "results/sediment/{sediment_data}/{sediment_data}_{grid_name}.nc",
    output:
        "results/sediment/tillphi/tillphi_{sediment_data}_{grid_name}.nc",
    params:
        sediment_threshold = 0.2,
        phi_min = 15,
        phi_max = 30,
        topg_min = -300,
        topg_max = 400,
        tauc_factor = 0.01
    shell:
        """
        python3 workflow/scripts/prepare_tillphi.py {input.topg} {input.sediment} none {output} \
            {params.sediment_threshold} \
            {params.phi_min} \
            {params.phi_max} \
            {params.topg_min} \
            {params.topg_max} \
            {params.tauc_factor} \

        """

