

rule download_present_day_greenland_file:
  output: "datasets/present_day_greenland/Greenland_5km_v1.1",
  shell:
    """
DATAVERSION=1.1
DATAURL=http://websrv.cs.umt.edu/isis/images/a/a5/
DATANAME=Greenland_5km_v$DATAVERSION.nc

echo "fetching master file ... "
wget -nc ${{DATAURL}}${{DATANAME}} -O {output}  # -nc is "no clobber"
echo "  ... done."
    """



rule present_day_greenland_sealevel:
  input: "datasets/present_day_greenland/Greenland_5km_v1.1",
  output: "datasets/sealevel/pism_dSL_Imbrie2006.nc",
  shell:
    """
# extract paleo-climate time series into files suitable for option
# -sea_level ...,delta_SL
DATANAME={input}
SLSERIES={output}
echo -n "creating paleo-sea-level file $SLSERIES from $DATANAME ... "
ncks -O -v sealeveltimes,sealevel_time_series $DATANAME $SLSERIES
ncrename -O -d sealeveltimes,time $SLSERIES
ncrename -O -v sealeveltimes,time $SLSERIES
ncrename -O -v sealevel_time_series,delta_SL $SLSERIES
# reverse time dimension
ncpdq -O --rdr=-time $SLSERIES $SLSERIES
# make times follow same convention as PISM
ncap2 -O -s "time=-time" $SLSERIES $SLSERIES
ncatted -O -a units,time,m,c,"years since 1-1-1" $SLSERIES
ncatted -O -a calendar,time,c,c,"365_day" $SLSERIES
echo "done."

# add time bounds (https://www.pism.io/docs/climate_forcing/time-dependent.html)
ncap2 -O -s 'defdim("nv",2);time_bnds=make_bounds(time,$nv,"time_bnds");' \
      $SLSERIES $SLSERIES
echo

    """
