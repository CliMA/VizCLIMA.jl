# # Plot Comparison Between Model Runs

# This plots zonal and time mean u anomalies from a control run (assumed to be the first in names below). Used for sensitivity analysis of parameter sweeps.

# Load modules
using Plots
using NCDatasets
using Statistics: mean

# Select the variable to plot
var_name = "u";

# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_ANALYSIS = "to_be_specified";
CLIMA_NETCDF = "to_be_specified";
RUNNAME = "to_be_specified";

# Get all netcdf file names with a specified string in the CLIMA_NETCDF directory
#fnames = filter(x -> occursin(Regex("^$RUNNAME"), x), readdir( CLIMA_NETCDF ) );
fnames = filter(x -> occursin("AtmosGCMDefault", x), readdir( CLIMA_NETCDF ) );

# Aggregate data in output into a multi-file dataset
nexp = size(fnames);

# Extract and postprocess data
function get_zonal_mean(file_name, var_name, t_spinup);
    ds = NCDataset(file_name, "r");
    lon = ds["long"][:];
    lat = ds["lat"][:];
    z = ds["level"][:] / 1e3; # height in kilometers
    time = ds["time"][:];  # time
    var = ds[var_name][:];
    var=var[t_spinup:end, :, :, :]; # cut out the spinup;
    data_time_zonal_mean = mean( mean(var, dims=1) , dims=4)[1,:,:,1]; # create statistics
    return lat, z, data_time_zonal_mean
    none
end


# ## Plotting

# Control
lat, z, zm_c= get_zonal_mean( "$CLIMA_NETCDF/"fnames[1], var_name, 1);
p_ctrl = contourf( lat, z, zm_c , title="$var_name (ctrl)", xlabel="lat (deg N)", ylabel="z (km)");

# Make anomaly plots and save them in an array
plot_array = Any[p_ctrl]; # can type this more strictly
for i in 2:nexp[1]
  lat, z, zm = get_zonal_mean( "$CLIMA_NETCDF/"fnames[i], var_name, 1);
  one_plot = contourf( lat, z, zm-zm_c, title="$var_name (exp$i-ctrl)", xlabel="lat (deg N)", ylabel="z (km)");
  push!(plot_array,one_plot); # make a plot and add it to the plot_array
end

# Plot and save the array of plots
fig=plot(plot_array...);
savefig(fig, string("$CLIMA_ANALYSIS/plot_$var_name","_ctrl_anomaly.pdf"));
