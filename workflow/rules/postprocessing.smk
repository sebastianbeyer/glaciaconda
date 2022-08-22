

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
