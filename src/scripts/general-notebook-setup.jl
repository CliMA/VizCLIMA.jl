# Load modules
using Plots
using NCDatasets
using Statistics: mean

# Setup run-time enviromnent
ENV["GKSwstype"] = "100"

# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_NETCDF = "../netcdf/";

# Get the current and previous  GCM netcdf file names in the CLIMA_NETCDF directory
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );
filename = "$CLIMA_NETCDF"fnames[end] # selects the last file on list

# extract data
ds = NCDataset(filename, "r");
close(ds)

