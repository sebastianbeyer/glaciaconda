
FILENAME = {
    "LGM_NOVEG": {
        "atmo":   "datasets/CESM/LGM_NOVEG/spin_up_21ka_CESM_noveg.cam.h0.0551to0600_clim.nc",
        "stddev": "datasets/CESM/LGM_NOVEG/TREFHT_spin_up_21ka_CESM_noveg.cam.h1.0551to0600_std.nc",
        "ocean":  "datasets/CESM/LGM_NOVEG/TandS_spin_up_21ka_CESM_noveg.pop.h.0551to0600_clim.nc"
    },
    "PD_LOWALBEDO": {
        "atmo":   "datasets/CESM/CESM1.2_CAM5_CN_PD_lowalbedo_Ute/b.e12.B2000C5_CN.f19_g16.PDalb.B4.cam.h0.0301to0400_clim.nc",
        "stddev": "datasets/CESM/CESM1.2_CAM5_CN_PD_lowalbedo_Ute/TREFHT_b.e12.B2000C5_CN.f19_g16.PDalb.B4.cam.h1.0301to0400_std.nc",
        "ocean":  "datasets/CESM/CESM1.2_CAM5_CN_PD_lowalbedo_Ute/TandS_b.e12.B2000C5_CN.f19_g16.PDalb.B4.pop.h.0301to0400_clim.nc"
    }
}



rule all:
    input:
        "results/CESM/LGM_NOVEG/LGM_NOVEG_NHEM_20km_atmo.nc",
        "results/CESM/LGM_NOVEG/LGM_NOVEG_NHEM_20km_ocean.nc",
        "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_NHEM_20km_atmo.nc",
        "results/CESM/PD_LOWALBEDO/PD_LOWALBEDO_NHEM_20km_ocean.nc",


rule CESM_atmo:
    input:
        atmo   = lambda wildcards: FILENAME[wildcards.CESM_exp_name]["atmo"],
        stddev = lambda wildcards: FILENAME[wildcards.CESM_exp_name]["stddev"],
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main      ="results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_atmo.nc",
        refheight ="results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_refHeight.nc"
    shell:
        "python3 workflow/scripts/prepare_CESM_atmo.py {input.grid} {input.atmo} {input.stddev} {output.main} {output.refheight}"


rule CESM_atmo_yearmean:
    input:
        atmo   = lambda wildcards: FILENAME[wildcards.CESM_exp_name]["atmo"],
        stddev = lambda wildcards: FILENAME[wildcards.CESM_exp_name]["stddev"],
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main      ="results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_atmo_yearmean.nc",
        refheight ="results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_refHeight_yearmean.nc"
    shell:
        "python3 workflow/scripts/prepare_CESM_atmo.py {input.grid} {input.atmo} {input.stddev} {output.main} {output.refheight} --yearmean"

rule CESM_ocean:
    input:
        ocean = lambda wildcards: FILENAME[wildcards.CESM_exp_name]["ocean"],
        grid  = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main = "results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_ocean.nc",
    shell:
        "python3 workflow/scripts/prepare_CESM_ocean.py {input.grid} {input.ocean} {output.main}"
rule CESM_ocean_yearmean:
    input:
        ocean = lambda wildcards: FILENAME[wildcards.CESM_exp_name]["ocean"],
        grid  = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main = "results/CESM/{CESM_exp_name}/{CESM_exp_name}_{grid_name}_ocean_yearmean.nc",
    shell:
        "python3 workflow/scripts/prepare_CESM_ocean.py {input.grid} {input.ocean} {output.main} --yearmean"

rule glacialindex:
    input:
        index = "datasets/glacialIndex/41586_2004_BFnature02805_MOESM1_ESM.csv",
    output:
        main = "results/glacialindex/glacialindex.nc",
    shell:
      "python3 workflow/scripts/prepare_glacialindex.py {input.index} {output.main}"

rule glacialindex_test:
    input:
    output:
        main = "results/glacialindex/test_glacialindex.nc",
    shell:
      "python3 workflow/scripts/generate_fake_glacialindex.py {output.main}"



rule CESM_atmo_MillenialScaleOscillations:
    input:
        atmo   = "datasets/CESM/millenialscaleoscillations/CESM_atmo_monthlymean_cycle_2578-4344.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main      ="results/CESM/MillenialScaleOscillations/CESM_MSO_{grid_name}_atmo.nc",
    shell:
        "cdo remapbil,{input.grid} {input.atmo} {output.main}"

rule CESM_ocean_MillenialScaleOscillations:
    input:
        ocean   = "datasets/CESM/millenialscaleoscillations/CESM_ocean_yearlymean_cycle_2578-4344.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main      ="results/CESM/MillenialScaleOscillations/CESM_MSO_{grid_name}_ocean.nc",
    shell:
        "cdo remapbil,{input.grid} {input.ocean} {output.main}"


rule CESM_atmo_MillenialScaleOscillations_refHeight:
    input:
        refheight   = "datasets/CESM/millenialscaleoscillations/CESM_refheight.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        refheight = "results/CESM/MillenialScaleOscillations/CESM_MSO_{grid_name}_refHeight.nc",
    conda:
        "../envs/dataprep.yaml",
    shell:
        "cdo remapbil,{input.grid} {input.refheight} {output.refheight}"



rule CESM_atmo_MSO_climatology:
    input:
        atmo   = "datasets/CESM/millenialscaleoscillations/CESM_cycle_climatology.nc",
        grid   = lambda wildcards: GRID[wildcards.grid_name],
    output:
        main   = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_{grid_name}_atmo.nc",
    conda:
        "../envs/dataprep.yaml",
    shell:
        """
        cdo remapbil,{input.grid} {input.atmo} {output.main}
        python3 workflow/scripts/set_climatology_time.py {output.main}
        """

rule CESM_atmo_MSO_climatology_delta_T:
    input:
        time_series = "datasets/CESM/millenialscaleoscillations/CESM_cycle_airtemp_mean.nc",
        climatology = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_{grid_name}_atmo.nc"
    output:
        main   = "results/CESM/MillenialScaleOscillations/CESM_MSO_climatology_{grid_name}_delta_T.nc"
    conda:
        "../envs/dataprep.yaml",
    shell:
        """
        python3 workflow/scripts/generate_delta_T.py {input.time_series} {input.climatology} {output.main} --smoothing 63
        ncap2 -O -s 'defdim("nv",2);time_bnds=make_bounds(time,$nv,"time_bnds");' {output.main} tmp_with_bnds.nc
        mv tmp_with_bnds.nc {output.main}
        """

