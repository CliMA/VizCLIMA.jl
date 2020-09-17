# Load modules
using Plots
using NCDatasets
using Statistics: mean
using DelimitedFiles
using PrettyTables
using PaddedViews
using Dates
using Printf

# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_NETCDF = "../netcdf/";

# Get the current and previous  GCM netcdf file names in the CLIMA_NETCDF directory
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );
filename = "$CLIMA_NETCDF"fnames[end] # selects the last file on list

# extract data
ds = NCDataset(file_name, "r");
lon = ds["long"][:];
lat = ds["lat"][:];
lev = ds["level"][:] / 1e3; # height in kilometers
time = ds["time"][:];
u = ds["u"][:];
v = ds["v"][:];
T = ds["temp"][:];
close(ds)

# zonal mean:T and u at last diagnostic time
time_index = length(time)
u_zm = mean( u[:,:,:,:], dims=1); # lon, lat,lev, time
T_zm = mean( T[:,:,:,:], dims=1); # lon, lat,lev, time

plot1 = contourf( lat, lev, (u_zm[:,:,time_index])', title="u", xlabel="lat (deg N)", ylabel="z (km)");
plot_array = [plot1]
plot2 = contourf( lat, lev, (T_zm[:,:,time_index])', title="T", xlabel="lat (deg N)", ylabel="z (km)");
push!(plot_array,plot2);
fig=plot(plot_array... , layout=(1, 2), size=(800, 400) )

# vertical slice of v at lev_index
lev_index = 10
z_in_km = lev[lev_index]
v_plot = contourf( lon, lat, ( (hs[:,:,1,1]-hs_c[:,:,1,1])*1.0 )', title="v @ $z_in_km", xlabel="lon (deg)", ylabel="lat (deg N)");
fig=plot(v_plot, layout=(1, 1), size=(800, 400) )
