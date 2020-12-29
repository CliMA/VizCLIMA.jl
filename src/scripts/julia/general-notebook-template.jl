# # Notebook Template

# Use this when using the end-to-end bash scripts to run ClimateMachine.jl and VizCLIMA.jl. These scripts use Literate.jl to automatically convert this .jl script to a Jupyter notebook in a pre-specified location.

# ## Load modules
using Plots
using NCDatasets
#using Statistics: mean
#using DelimitedFiles
#using PrettyTables
#using PaddedViews
#using Dates
#using Printf 

# ## Setup run-time enviromnent 
ENV["GKSwstype"] = "100"

# ## Extract data

# Specify location of .nc files
CLIMA_NETCDF = "../netcdf/";

# Get all netcdf file names in the CLIMA_NETCDF directory and select the last one
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );
filename = "$CLIMA_NETCDF"fnames[end] 

# Open file and print its info
ds = NCDataset(filename, "r");
println(ds)
close(ds)

# ## View/modify your notebook on a local machine
# on remote terminal (e.g. login2): jupyter notebook --no-browser --port=9999
# on local terminal: ssh -N -f -L 9999:localhost:9999 <yourusername>@login2.hpc.caltech.edu
# in local browser: localhost:9999
# see https://github.com/CliMA/ClimateMachine.jl/wiki/Visualization
