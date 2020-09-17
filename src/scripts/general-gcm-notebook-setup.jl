# Load modules
using Plots
using NCDatasets
using Statistics: mean
using DelimitedFiles
using PrettyTables
using PaddedViews
using Dates
using Printf 

# Useful functions
function get_var(file_name, var_name, t_spinup, nan_fill_value);
    ds = NCDataset(file_name, "r");
    lon = ds["long"][:];
    lat = ds["lat"][:];
    z = ds["level"][:] / 1e3; # height in kilometers
    time = ds["time"][:];  # time
    var = ds[var_name][:];
    data=var[:, :, :, t_spinup:end]; # cut out the spinup;
    replace!(data, NaN=>nan_fill_value)
    return time, z, lat, lon, data
    none
end

function get_timezonal_mean(file_name, var_name, t_spinup,nan_fill_value);
    ds = NCDataset(file_name, "r");
    lon = ds["long"][:];
    lat = ds["lat"][:];
    z = ds["level"][:] / 1e3; # height in kilometers
    time = ds["time"][:]; 
    var = ds[var_name][:];
    var=var[:, :, :, t_spinup:end]; # cut out the spinup;
    data_mean = mean(  mean( var[:,:,:,:], dims=4), dims=1); # lon, lat,lev, time
    replace!(data_mean, NaN=>nan_fill_value)
    return lat, z , data_mean
    none
end

function get_min_max(var);
    vmax = maximum(filter(!isnan,var))
    vmin = minimum(filter(!isnan,var))
    return vmin,vmax
    none
end



# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_ANALYSIS = "tbd"
CLIMA_NETCDF = "tbd";
CLIMA_LOGFILE = "tbd";
RUNNAME = "tbd";

# Get the current and previous  GCM netcdf file names in the CLIMA_NETCDF directory
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );


# set file name 
filename = "$CLIMA_NETCDF/"fnames[1]

# extract data
ds = NCDataset(filename, "r")
close(ds)

# plot spectrum
plot(k,spec[:,2], label = "timestep: $(time[2])", title = "3D power spec", xlims = (0,30), xlabel = "k", ylabel = "ps")

