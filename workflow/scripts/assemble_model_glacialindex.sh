#!/usr/bin/env bash

set -euo pipefail

atmo0=$1
atmo1=$2
ocean0=$3
ocean1=$4
refheight0=$5
refheight1=$6
index=$7
heatflux=$8
topg=$9
thk=${10}
oceankill=${11}
till_phi=${12}
output=${13}

# convert to netcdf3 because in 4 the renaming of dimensions does not
# work
ncks -O -3 "$atmo0" tmp_atmo0_netcdf3.nc
ncrename -O -v time,time_periodic \
         -v time_bnds,time_bnds_periodic \
         -v air_temp,airtemp_0 \
         -v precipitation,precip_0 \
         -v air_temp_sd,airtempsd_0 \
         -d time,time_periodic \
         tmp_atmo0_netcdf3.nc atmo0_tmp.nc
ncks -O --fix_rec_dmn time_periodic atmo0_tmp.nc atmo0_tmp2.nc

ncks -O -3 "$atmo1" tmp_atmo1_netcdf3.nc
ncrename -O -v time,time_periodic \
         -v time_bnds,time_bnds_periodic \
         -v air_temp,airtemp_1 \
         -v precipitation,precip_1 \
         -v air_temp_sd,airtempsd_1 \
         -d time,time_periodic \
         tmp_atmo1_netcdf3.nc atmo1_tmp.nc
ncks -O --fix_rec_dmn time_periodic atmo1_tmp.nc atmo1_tmp2.nc


ncks atmo0_tmp2.nc "$output"
ncks -A atmo1_tmp2.nc "$output"

rm tmp_atmo0_netcdf3.nc atmo0_tmp.nc atmo0_tmp2.nc
rm tmp_atmo1_netcdf3.nc atmo1_tmp.nc atmo1_tmp2.nc

## reference height
ncrename -O -v referenceHeight,usurf_0 $refheight0 refheight0_tmp.nc
ncrename -O -v referenceHeight,usurf_1 $refheight1 refheight1_tmp.nc

ncatted -O -a standard_name,usurf_0,d,, refheight0_tmp.nc
ncatted -O -a standard_name,usurf_1,d,, refheight1_tmp.nc

ncks -A refheight0_tmp.nc "$output"
ncks -A refheight1_tmp.nc "$output"

rm refheight0_tmp.nc
rm refheight1_tmp.nc

# currently no index for the ocean is possible, so just use present day
ncks -3 "$ocean0" tmp_ocean0_netcdf3.nc
ncrename -v time,time_periodic \
         -v time_bnds,time_bnds_periodic \
         -d time,time_periodic \
         tmp_ocean0_netcdf3.nc ocean0_tmp.nc
ncks --fix_rec_dmn time_periodic ocean0_tmp.nc ocean0_tmp2.nc
ncks -A ocean0_tmp2.nc "${output}"

rm tmp_ocean0_netcdf3.nc ocean0_tmp.nc ocean0_tmp2.nc

ncks -A "$index" "$output"

ncks -A "$heatflux" "$output"
ncks -A -v topg  "$topg" "$output"
ncks -A -v thk  "$thk" "$output"
ncks -A  "$oceankill" "$output"

if [ "$till_phi" != "none" ]; then
    ncks -A "$till_phi" "$output"
fi
# make time use time bounds periodic
ncatted -O -a bounds,time_periodic,o,c,"time_bnds_periodic" "$output"

ncatted -a _FillValue,glac_index,d,, "$output"
ncatted -a _FillValue,time_bnds,d,, "$output"

# delete history
ncatted -a history,global,d,, "$output"
ncatted -a history_of_appended_files,global,d,, "$output"

