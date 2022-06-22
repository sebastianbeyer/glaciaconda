
GRID = {
    "NHEM_20km": "resources/grids/CDO_grid_NHEM_20.0km.nc",
    "NHEM_40km": "resources/grids/CDO_grid_NHEM_40.0km.nc",
    "GRN_20km" : "resources/grids/CDO_grid_GRNSearise_20.0km.nc",
}


wildcard_constraints:
  grid_name="[A-Z]{3,4}_\d{1,2}km"
