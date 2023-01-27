

#rule combine_ts_files:
#  input: [f"ts_gi_heinrich_{x}_{x+5000}.nc" for x in np.arange(-120000, -80000, 5000)]
#  output: "ts_gi_heinrich_-120000_-80000.nc"
#  shell: "ncrcat {input} {output}"
#

# this is needed for the plotscript to determine between different regions
# (Laurentide, Eurasia, ...)
rule region_files_plot:
  input:
    shapefile = "datasets/NHEM_regions/NHEM_regions_for_plots.shp",
    grid      = lambda wildcards: GRID[wildcards.grid_name],
  output:
    main = "results/NHEM_regions_for_plots/plot_regions_{grid_name}.nc",
  shell:
        "bash workflow/scripts/plot/make_NHEM_regions_for_plot.sh {input.grid} {input.shapefile} {output.main}"


rule plot_surges_1d:
  input:
    main = "results/PISM_results/yearmean_compare/ex_yearmean_compare_yearmean.nc",
    regions = "results/NHEM_regions_for_plots/plot_regions_{grid_name}.nc",
  output:
    main = "results/plots/{exp_name}/{exp_name}_{grid_name}_surges.png",
  shell:
    "bash workflow/scripts/plot/plot_surges_1d.py {input.main} {input.regions} {output.main}"

rule plot_MSO_1d:
  input:
    main = "results/PISM_results/MillenialScaleOscillations_climatology/ex_MillenialScaleOscillations_climatology_NHEM_20km.nc",
    regions = "results/NHEM_regions_for_plots/plot_regions_NHEM_20km.nc",
  output:
    main = "results/plots/MSO_climatology/MSO_climatolotgy_NHEM20km_surges.png",
  conda:
    "../envs/plotting.yaml",
  shell:
    "python3 workflow/scripts/plot/plot_surges_1d.py {input.main} {input.regions} {output.main}"


rule plot_sealevel:
  input:
    main = "results/PISM_results_large/{experiment}/ts_{subexperiment}.nc",
    #ref_sealevel = "",
    #regions = "results/NHEM_regions_for_plots/plot_regions_NHEM_20km.nc",
  output:
    main = "results/PISM_results_large/{experiment}/{subexperiment}_sealevel.png",
  conda:
    "../envs/plotting.yaml",
  shell:
    "python3 workflow/scripts/plot/plot_sealevel.py --observed datasets/sealevel/pism_dSL_Imbrie2006.nc {input.main} {output.main}"




def timestep_for_video(wildcards):
        return int(wildcards.number) % 50

def get_input_from_timestep(wildcards):
    # compute the correct file according to the timestep given
    base = "results/PISM_results_large/gi_cold_mprange_clemdyn/"

    # a new file starts every 50 steps
    fileindex = int(wildcards.number) // 50

    startyear = -120000 + fileindex * 5000
    endyear = startyear + 5000

    return base + f"ex_gi_cold_mprange_clemdyn_{startyear}_{endyear}.nc"



rule plot_glacialindexvideo:
  input:
    # main = "./results/PISM_results_large/gi_cold_mprange_clemdyn",
    main = get_input_from_timestep,
  output:
    main = "results/videos/GI_frames/GI{number}.png",
  resources:
    timestep = timestep_for_video,
  conda:
    "../envs/hyoga.yaml",
  shell:
    "python3 workflow/scripts/plot/plot_nhem_nice.py {input.main} {output.main} --timestep {resources.timestep}"

rule all_gi_video:
    input: expand("results/videos/GI_frames/GI{i:05d}.png", i=range(0,22))

