

rule topo:
    input:
        "results/topography/ETOPO1/ETOPO1_NHEM_20km.nc",
        "results/topography/ICE7GNA/ICE7GNA_NHEM_20km.nc",
        "results/oceankill/oceankill_ICE7GNA_NHEM_20km.nc",

rule ETOPO1:
    resources:
        time = "00:10:00"
    conda:
        "../envs/dataprep.yaml",
    input:
        topg = "datasets/ETOPO1/ETOPO1_Bed_g_gmt4.grd",
        thk  = "datasets/ETOPO1/ETOPO1_Ice_g_gmt4.grd",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/topography/ETOPO1/ETOPO1_{grid_name}.nc",
    shell:
        """
        python3 workflow/scripts/prepare_ETOPO1.py {input.grid} {input.topg} {input.thk} output_tmp.nc
        ncatted -O -a _FillValue,,d,, output_tmp.nc
        ncatted -O -a missing_value,,d,, output_tmp.nc
        ncatted -O -a actual_range,,d,, output_tmp.nc
        cdo copy output_tmp.nc {output}
        rm output_tmp.nc
        """


rule ICE7GNA:
    resources:
        time = "00:10:00"
    conda:
        "../envs/dataprep.yaml",
    input:
        main = "datasets/ICE-7G_NA/I7G_NA.VM7_1deg.21.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/topography/ICE7GNA/ICE7GNA_{grid_name}.nc",
    shell:
        "python3 workflow/scripts/prepare_ICE-7G.py {input.grid} {input.main} {output} "

rule glac1d_download_nn9927NAGrB120kto30k:
    output:
        "datasets/glac1d_website/GLAC1Dnn9927NAGrB120kto30k.nc",
    shell:
        """
        wget -O {output} https://www.physics.mun.ca/~lev/GLAC1Dnn9927NAGrB120kto30k.nc
        """

rule glac1d_download_GLAC1Dnn9927NAGrB30kto0k:
    output:
        "datasets/glac1d_website/GLAC1Dnn9927NAGrB30kto0k.nc",
    shell:
        """
        wget -O {output} https://www.physics.mun.ca/~lev/GLAC1Dnn9927NAGrB30kto0k.nc
        """

rule glac1d_download_nn9894NAGrB120kto30k:
    output:
        "datasets/glac1d_website/GLAC1Dnn9894NAGrB120kto30k.nc",
    shell:
        """
        wget -O {output} https://www.physics.mun.ca/~lev/GLAC1Dnn9894NAGrB120kto30k.nc
        """

rule glac1d_download_GLAC1Dnn9894NAGrB30kto0k:
    output:
        "datasets/glac1d_website/GLAC1Dnn9894NAGrB30kto0k.nc",
    shell:
        """
        wget -O {output} https://www.physics.mun.ca/~lev/GLAC1Dnn9894NAGrB30kto0k.nc
        """

rule glac1d_download_GLAC1Dnn4041ANT30kto0k:
    output:
        "datasets/glac1d_website/GLAC1Dnn4041ANT30kto0k.nc",
    shell:
        """
        wget -O {output} https://www.physics.mun.ca/~lev/GLAC1Dnn4041ANT30kto0k.nc
        """

rule glac1d_download_GLAC1Dnn4041ANT120kto30k:
    output:
        "datasets/glac1d_website/GLAC1Dnn4041ANT120kto30k.nc",
    shell:
        """
        wget -O {output} https://www.physics.mun.ca/~lev/GLAC1Dnn4041ANT120kto30k.nc
        """


rule glac1d_nn9927:
    resources:
      time = "00:10:00",
    conda:
        "../envs/dataprep.yaml",
    wildcard_constraints:
        time="\d+kto\d+k"
    input:
        main = "datasets/glac1d_website/GLAC1Dnn{glacversion}NAGrB{time}.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        "results/topography/GLAC1D/GLAC1D_nn{glacversion}_NaGrB_{time}_thk_{grid_name}.nc",
    params:
        timevar = lambda wildcards: "T120K" if wildcards.time == "120kto30k" else "T122KP11"
    shell:
        """
        ncks -O -3 {input.main} {output}_tmp # because ncrename does not work with netcdf4
        ncrename -O -v {params.timevar},time -d {params.timevar},time {output}_tmp
        ncatted -O -a units,time,o,c,"years since 1-1-1" {output}_tmp
        ncatted -O -a calendar,time,o,c,"365_day" {output}_tmp
        ncap2 -s 'time=time*1000-1' {output}_tmp 
        cdo -setmissval,0 -chname,HICE,thk -remapbil,{input.grid} -selvar,HICE {output}_tmp {output}
        ncatted -O -a _FillValue,,d,, {output}
        ncatted -O -a missing_value,,d,, {output}
        ncatted -O -a long_name,thk,d,, {output}
        ncatted -O -a source,thk,o,c,"Tarasov GLAC1Dnn{wildcards.glacversion}NAGrB120kto30k" {output}
        ncatted -O -a units,thk,o,c,"m" {output}
        ncatted -O -a standard_name,thk,o,c,"land_ice_thickness" {output}
        rm {output}_tmp
        """

rule glac1d_singleyear:
    resources:
      time = "00:10:00",
    conda:
        "../envs/dataprep.yaml",
    input:
        lambda wildcards: f"results/topography/GLAC1D/GLAC1D_nn{wildcards.glacversion}_NaGrB_120kto30k_thk_{wildcards.grid_name}.nc" if int(wildcards.year) <= -30000 else f"results/topography/GLAC1D/GLAC1D_nn{wildcards.glacversion}_NaGrB_30kto0k_thk_{wildcards.grid_name}.nc" 
    params:
        year = "{year}",
        #time_string = lambda wildcards: "120kto30k" if wildcards.year >= 30 else "30kto0k"
    wildcard_constraints:
        year="-\d+"
    output:
        "results/topography/GLAC1D/GLAC1D_nn{glacversion}_NaGrB_{year}k_thk_{grid_name}.nc",
    shell:
        """
        # need timmean, because selyear does not accept --reduce_dim
        cdo --reduce_dim -timmean -selyear,{params.year} {input} {output}
        """

rule oceankillmask:
    conda:
        "../envs/dataprep.yaml",
    input:
      "results/topography/{topography}/{topography}_{grid_name}.nc"
    output:
        "results/oceankill/oceankill_{topography}_{grid_name}.nc",
    shell:
        "python3 workflow/scripts/prepare_oceankillmask.py {input} {output} --remove_himalaya"
