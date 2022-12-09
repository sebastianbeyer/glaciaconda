
Okay, let's go! 

##Infrastructure: 

There is the ice model, managed through spack. My older notes on that are still
valid, I think, you may need to update the spack repo and then the main model
versions are pism@2.0.5 (official, but I had to add a patch in the spack file
to make it work on hlrn) and there is sbeyer-pism@current. The latter is my
current version that is (at this time) based on pism 2.0.4 (need to check) but
it also contains the code for glacial index modelling.

All the data preparation is managed in
[snakemake](https://snakemake.readthedocs.io/en/stable/) now, which is
basically a bunch of Makefiles with a lot of python added. The idea is to have
dependencies of model setups managed by it, be it preparation of datasets,
different time periods of runs or else. You make a setup and then you can run
it and see what dependencies might need to be updated first. It also allows for
easy switching between different sets of parameters or input files as well as
parameter tests. It is aware of conda environments, so running the scripts with
all the required libraries should not be a problem. The structure is as
follows:

```
config/ <- config for different parameter sets and defaults
datasets/ 
resources/ <- so far only template grids for reprojection are stored here
results/ <- here results are being saved, not only for PISM results, but also intermediate stuff, like reprojected/preprocessed datasets
slurmsimple/ <- config for slurm submission
workflow/
  envs/ <- yaml files that describe conda envs and can be loaded by rules
  rules/ <- the rules themselves
  scripts/ <- the scripts that are used for preprocessing and plotting
  Snakefile <- the main makefile that uses include statements to include rules from the rules/ directory
```

> **Note**
> The main problem with this stuff is that the conda environments get quite large
> quickly (quota and number of inodes). This is also a problem with spack, but
> you can put the spack installation into `$WORK`, it does not have as many files as conda.


To run a pism run (or any other rule) with slurm you need to
```
snakemake results/PISM_results_large/MSO_clim_dT_mprange_clemdyn/MSO_clim_dT_mprange_clemdyn_base_NHEM_20km_45000_50000.nc --profile slurmsimple
```

For a run that should not be run via slurm, but simply on the login nodes (almost all the preprocessing) you need to 
```
snakemake results/PISM_results_large/MSO_clim_dT_mprange_clemdyn/MSO_clim_dT_mprange_clemdyn_base_NHEM_20km_45000_50000.nc --use-conda -c 1
```

Note the `--use-conda` if the rule(s) require using an environment (they usually do) and the `-c 1` argument which tells snakemake how many cores to use.
If you only want to check what rules would be executed and if you set up the rules correctly, you can give `-p -n` which will only print the rules to be executed.

> **Note** 
> Once you start a run you can not disconnect from hlrn, so I suggest using `tmux`. 
> There is also an option to use and argument like
> `--immediate-submit` or similar in snakemake, but I have not yet tested it.
