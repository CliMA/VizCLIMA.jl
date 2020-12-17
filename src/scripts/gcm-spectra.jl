# GCM EKE Spectra

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
#filename = "/central/scratch/elencz/output/gcm_spectrum/netcdf/HeldSuarez_AtmosGCMSpectra-2020-12-07T10.10.33.674.nc"

# Setup run-time enviromnent
ENV["GKSwstype"] = "100"

# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_NETCDF = "../netcdf/";

# Get the current and previous  GCM netcdf file names in the CLIMA_NETCDF directory
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );
filename = "$CLIMA_NETCDF"fnames[end] # selects the last file on list

# extract data
ds = NCDataset(filename, "r")
spec1 = ds["spectrum_1d"][:] # m, lat, lev, time, 
spec2 = ds["spectrum_2d"][:] # m_t, n, lev, time, 
time = ds["time"][:]
lev = ds["level"][:]
lat = ds["lat"][:]
m = ds["m"][:]
n = ds["n"][:]
m_t = ds["m_t"][:]
close(ds)


# plot spectrum
#plot(m,spec[:,2], label = "timestep: $(time[2])", title = "3D power spec", xlims = (0,30), xlabel = "k", ylabel = "ps")

plot(n, sum(spec2[:,:,4,5], dims = 1)[1,:] )



