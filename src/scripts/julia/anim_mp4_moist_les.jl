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
#print(fnames)

filename = "$CLIMA_NETCDF"fnames[end] # selects the last file on list

# extract data
ds = NCDataset(filename, "r");
print(ds)
x = ds["x"][:] 
y = ds["y"][:]
z = ds["z"][:]
time = ds["time"][:]

ρqliq = ds["moisture.q_liq"][:] # e.g. select q_liq to visualise clouds

function get_min_max(var);
    vmax = maximum(filter(!isnan,var))
    vmin = minimum(filter(!isnan,var))
    return vmin,vmax
    none
end

# Animation
clims = ( get_min_max(ρqliq) )
diag_dt_days =  (time[2] - time[1]).value / (1000*60*60*24) # get simtime

anim = @animate for t_i in 1:length(time)
    one_plot = contourf( x, z, (ρqliq[:,y_i,:,t_i] )',  xlabel="x (m)", ylabel="z (m)", clims = clims)   
    plot(one_plot, layout=(1,1), size=(400, 400) ) 
end
mp4(anim, "plot_y_slice_anim.gif", fps = 3) # NB: mp4 can be more flaky than gif


