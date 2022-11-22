
GRID = {
    "NHEM_20km": "resources/grids/CDO_grid_NHEM_20.0km.nc",
    "NHEM_40km": "resources/grids/CDO_grid_NHEM_40.0km.nc",
    "GRN_20km" : "resources/grids/CDO_grid_GRNSearise_20.0km.nc",
}


wildcard_constraints:
  grid_name="[A-Z]{3,4}_\d{1,2}km"

import pandas as pd
PISM_parameters = pd.read_csv("config/parameters.csv", skipinitialspace=True, index_col="name")


def get_dynamics_from_parameters(wildcards):
    name = wildcards.paramset
    dynamics = [
        "-stress_balance ssa+sia",
        "-pseudo_plastic True",
        f"-sia_e {PISM_parameters.loc[name]['sia_e']}",
        f"-ssa_e {PISM_parameters.loc[name]['ssa_e']}",
        f"-pseudo_plastic_q {PISM_parameters.loc[name]['ppq']}",
        f"-till_effective_fraction_overburden {PISM_parameters.loc[name]['till_fraction']}",
        ]
    dynamics_string = " \\\n".join(dynamics)
    return dynamics_string

def get_calving_from_parameters(wildcards):
    name = wildcards.paramset
    calving = [
        "-calving eigen_calving,thickness_calving",
        f"-thickness_calving_threshold {PISM_parameters.loc[name]['calving_thk_thresh']}",
        f"-calving.eigen_calving.K {PISM_parameters.loc[name]['calving_eigen_thresh']}",
        ]
    calving_string = " \\\n".join(calving)
    return calving_string

def get_climate_pdd_from_parameters(wildcards, input):
    name = wildcards.paramset
    climate = [
        "-atmosphere given,elevation_change",
        f"-atmosphere_lapse_rate_file {input.refheight}",
        f"-temp_lapse_rate {PISM_parameters.loc[name]['lapserate_temp']}",
        "-surface pdd",
        f"-pdd_sd_file {input.main}",
        f"-surface.pdd.factor_ice {PISM_parameters.loc[name]['pdd_factor_ice']}",
        f"-surface.pdd.factor_snow {PISM_parameters.loc[name]['pdd_factor_snow']}",
        f"-surface.pdd.refreeze {PISM_parameters.loc[name]['pdd_refreeze']}",
        f"-surface.pdd.air_temp_all_precip_as_rain {PISM_parameters.loc[name]['airtemp_all_rain']}",
        f"-surface.pdd.air_temp_all_precip_as_snow {PISM_parameters.loc[name]['airtemp_all_snow']}",
        ]
    climate_string = " \\\n".join(climate)
    return climate_string

def get_climate_pdd_deltaT_from_parameters(wildcards, input):
    name = wildcards.paramset
    climate = [
        "-atmosphere given,delta_T,delta_P,elevation_change",
        f"-atmosphere_lapse_rate_file {input.refheight}",
        f"-atmosphere.delta_T.file {input.delta_t}",
        f"-atmosphere.delta_P.file {input.delta_p}",
        "-atmosphere.delta_T.periodic True",
        "-atmosphere.delta_P.periodic True",
        f"-temp_lapse_rate {PISM_parameters.loc[name]['lapserate_temp']}",
        "-surface pdd",
        f"-pdd_sd_file {input.main}",
        f"-surface.pdd.factor_ice {PISM_parameters.loc[name]['pdd_factor_ice']}",
        f"-surface.pdd.factor_snow {PISM_parameters.loc[name]['pdd_factor_snow']}",
        f"-surface.pdd.refreeze {PISM_parameters.loc[name]['pdd_refreeze']}",
        f"-surface.pdd.air_temp_all_precip_as_rain {PISM_parameters.loc[name]['airtemp_all_rain']}",
        f"-surface.pdd.air_temp_all_precip_as_snow {PISM_parameters.loc[name]['airtemp_all_snow']}",
        ]
    climate_string = " \\\n".join(climate)
    return climate_string

def get_climate_indexforcing_from_parameters(wildcards, input):
    name = wildcards.paramset
    climate = [
        "-atmosphere index_forcing",
        f"-atmosphere_index_file {input.main}",
        "-surface pdd",
        f"-surface.pdd.factor_ice {PISM_parameters.loc[name]['pdd_factor_ice']}",
        f"-surface.pdd.factor_snow {PISM_parameters.loc[name]['pdd_factor_snow']}",
        f"-surface.pdd.refreeze {PISM_parameters.loc[name]['pdd_refreeze']}",
        f"-surface.pdd.air_temp_all_precip_as_rain {PISM_parameters.loc[name]['airtemp_all_rain']}",
        f"-surface.pdd.air_temp_all_precip_as_snow {PISM_parameters.loc[name]['airtemp_all_snow']}",
        ]
    climate_string = " \\\n".join(climate)
    return climate_string

def get_always_on_parameters(wildcards):
    always_on = config['PISM_always_on']
    always_on_string = " \\\n".join(always_on)
    return always_on_string

def get_PISM_marine_ice_sheets_parameters(wildcards):
    params = config['PISM_marine_ice_sheets']
    params_string = " \\\n".join(params)
    return params_string
    
   
    
