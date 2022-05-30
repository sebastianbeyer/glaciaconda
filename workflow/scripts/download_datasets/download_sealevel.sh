#!/usr/bin/env bash

# adapted from
# https://github.com/pism/pism/blob/master/examples/std-greenland/preprocess.sh

targetfile=$1

set -e

# get file; see page http://websrv.cs.umt.edu/isis/index.php/Present_Day_Greenland
DATAVERSION=1.1
DATAURL=http://websrv.cs.umt.edu/isis/images/a/a5/
DATANAME=Greenland_5km_v$DATAVERSION.nc

wget -nc ${DATAURL}${DATANAME}   # -nc is "no clobber"

echo ""
echo "# download presen day greenland"
echo ""
if [ ! -f "$DATANAME" ] ; then
  echo "downloading ..."
	wget -nc  ${DATAURL}${DATANAME}
else
  echo "using $DATANAME without download"
fi


# extract paleo-climate time series into files suitable for option
# -atmosphere ...,delta_T
TEMPSERIES=pism_dT.nc
echo -n "creating paleo-temperature file $TEMPSERIES from $DATANAME ... "
ncks -O -v oisotopestimes,temp_time_series $DATANAME $TEMPSERIES
ncrename -O -d oisotopestimes,time      $TEMPSERIES
ncrename -O -v temp_time_series,delta_T $TEMPSERIES
ncrename -O -v oisotopestimes,time      $TEMPSERIES
# reverse time dimension
ncpdq -O --rdr=-time $TEMPSERIES $TEMPSERIES
# make times follow same convention as PISM
ncap2 -O -s "time=-time" $TEMPSERIES $TEMPSERIES
ncatted -O -a units,time,m,c,"years since 1-1-1" $TEMPSERIES
ncatted -O -a calendar,time,c,c,"365_day" $TEMPSERIES
ncatted -O -a units,delta_T,m,c,"Kelvin" $TEMPSERIES
echo "done."
echo

# extract paleo-climate time series into files suitable for option
# -sea_level ...,delta_SL
SLSERIES=pism_dSL_Imbrie2006.nc
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
echo

mv $SLSERIES $targetfile
