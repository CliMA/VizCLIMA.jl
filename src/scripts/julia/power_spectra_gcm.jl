# # GCM EKE Spectra

# ## Load modules
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

# Get the spectra data
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

# ## Plot the power spectrum
t_i = length(time)
l_1 = 1
plot(n, sum(spec2[:,:,l_1,t_i], dims = 1)[1,:], title = "EKE power spec at time $(time[t_i])", xlabel = "n", ylabel = "(m2/s2)" )



