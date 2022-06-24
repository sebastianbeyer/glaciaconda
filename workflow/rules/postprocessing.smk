


#rule combine_ts_files:
#  input: [f"ts_gi_heinrich_{x}_{x+5000}.nc" for x in np.arange(-120000, -80000, 5000)]
#  output: "ts_gi_heinrich_-120000_-80000.nc"
#  shell: "ncrcat {input} {output}"
