

rule laskemasters:
    input:
        "results/sediment/LaskeMasters/LaskeMasters_NHEM_20km.nc",

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

