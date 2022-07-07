

rule shapiro:
    input:
      "results/heatflux/shapiro/shapiro_NHEM_20km.nc",

rule heatflux_shapiro:
    resources:
        time = "00:10:00"
    input:
        heatflux = "datasets/shapiro/hfmap_Shapiro2004_global_1deg.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/heatflux/shapiro/shapiro_{grid_name}.nc",
    shell:
        "python3 workflow/scripts/prepare_shapiro.py {input.grid} {input.heatflux} {output} "

