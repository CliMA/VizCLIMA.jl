# # Load modules
using Plots
using NCDatasets
using Statistics: mean
using DelimitedFiles
using PrettyTables
using PaddedViews
using Dates
using Printf 

# ## Setup run-time enviromnent 
ENV["GKSwstype"] = "100"

# ## Extract data

# Specify location of .nc files
CLIMA_NETCDF = "../netcdf/";

# Get all netcdf file names in the CLIMA_NETCDF directory and select the last one
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );
filename = "$CLIMA_NETCDF"fnames[end] 

# Get the spectrum data
ds = NCDataset(filename, "r")
spec = ds["spectrum"][:]
k = ds["k"][:]
time = ds["time"][:]
close(ds)

# ## Plot spectrum
plot(k,spec[:,2], label = "timestep: $(time[2])", title = "3D power spec", xlims = (0,30), xlabel = "k", ylabel = "ps")

