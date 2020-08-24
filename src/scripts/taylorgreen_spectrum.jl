# Load modules
using Plots
using NCDatasets
using Statistics: mean
using DelimitedFiles
using PrettyTables
using PaddedViews
using Dates
using Printf 

# set file name 
filename = "/central/scratch/elencz/output/spectral_tst/netcdf/GreenVortex_Spectra-2020-08-20T10.25.22.564.nc"

# extract data
ds = NCDataset(filename, "r")
spec = ds["spectrum"][:]
k = ds["k"][:]
time = ds["time"][:]
close(ds)

# plot spectrum
plot(k,spec[:,2], label = "timestep: $(time[2])", title = "3D power spec", xlims = (0,30), xlabel = "k", ylabel = "ps")

