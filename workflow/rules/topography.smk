

rule topo:
    input:
        "results/topography/ETOPO1/ETOPO1_NHEM_20km.nc",
        "results/topography/ICE7GNA/ICE7GNA_NHEM_20km.nc",

rule ETOPO1:
    conda: "../envs/base.yaml"
    resources:
        time = "00:10:00"
    input:
        topg = "datasets/ETOPO1/ETOPO1_Bed_g_gmt4.grd",
        thk  = "datasets/ETOPO1/ETOPO1_Ice_g_gmt4.grd",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
    shell:
        "python3 workflow/scripts/prepare_ETOPO1.py {input.grid} {input.topg} {input.thk} {output} "

rule ICE7GNA:
    conda: "../envs/base.yaml"
    resources:
        time = "00:10:00"
    input:
        main = "datasets/ICE-7G_NA/I7G_NA.VM7_1deg.21.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/topography/ICE7GNA/ICE7GNA_{grid_name}.nc",
    shell:
        "python3 workflow/scripts/prepare_ICE-7G.py {input.grid} {input.main} {output} "
