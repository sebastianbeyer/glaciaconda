rule pism_example_preprocess:
    output:
        "results/PISM_example/Greenland_5km_v1.1.nc",
        "results/PISM_example/pism_dSL.nc",
        "results/PISM_example/pism_dT.nc",
    conda:
        "../envs/dataprep.yaml",
    shell:
        "./workflow/scripts/pism_example_preprocess.sh"

rule pism_example_run_sia:
  input:
    "results/PISM_example/Greenland_5km_v1.1.nc",
  output:
    main = "results/PISM_results/PISM_example/PISM_example_sia.nc",
    ex   = "results/PISM_results/PISM_example/ex_PISM_example_sia.nc",
    ts   = "results/PISM_results/PISM_example/ts_PISM_example_sia.nc",
  resources:
    nodes = 1,
    partition = "standard96:test",
    time = "1:00:00"
  shell:
    """
spack load pism-sbeyer@current\\

srun pismr \\
-i {input} \\
-o {output.main}.nc
-Mx 76 -My 141 -Mz 101 -Mbz 11 \\
-z_spacing equal -Lz 4000 -Lbz 2000 \\
-skip -skip_max 10 \\
-grid.recompute_longitude_and_latitude false \\
-grid.registration corner \\
-ys -10000 \\
-ye 0 \\
-surface given \\
-surface_given_file \\
pism_Greenland_5km_v1.1.nc \\
-front_retreat_file pism_Greenland_5km_v1.1.nc \\
-sia_e 3.0 \\
-ts_file {output.ts} \\
-ts_times -10000:yearly:0 \\
-extra_file {output.ex} \\
-extra_times -10000:100:0 \\
-extra_vars diffusivity,temppabase,tempicethk_basal,bmelt,tillwat,velsurf_mag,mask,thk,topg,usurf \\

"""


