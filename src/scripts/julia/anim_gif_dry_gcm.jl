# # Basic GCM plots and gif animation

# Useful for initial data exploration and debugging

# Load modules
using Plots
using NCDatasets
using Statistics: mean

# ## Setup run-time enviromnent 
ENV["GKSwstype"] = "100"

# ## Extract data

# Specify location of .nc files
CLIMA_NETCDF = "../netcdf/";

# Get all netcdf file names in the CLIMA_NETCDF directory and select the last one
fnames = filter(x -> occursin(".nc", x), readdir( CLIMA_NETCDF ) );
file_no = length(fnames)
filename = "$CLIMA_NETCDF"fnames[file_no] 

# Create a directory for the plots
plot_dir = fnames[file_no]*"_plots/"
mkdir(plot_dir)

# Get data
ds = NCDataset(filename, "r");
lon = ds["long"][:];
lat = ds["lat"][:];
lev = ds["level"][:] / 1e3; # height in kilometers
time = ds["time"][:];
u = ds["u"][:];
v = ds["v"][:];
T = ds["temp"][:];
close(ds)

# ## Zonal mean:
# T and u at last diagnostic time
time_index = length(time)
u_zm = mean( u[:,:,:,:], dims=1)[1,:,:,:]; # lon, lat,lev, time
T_zm = mean( T[:,:,:,:], dims=1)[1,:,:,:]; # lon, lat,lev, time
v_zm = sqrt.(mean( v[:,:,:,:] .^ 2, dims=1)[1,:,:,:]); # lon, lat,lev, time

plot1 = contourf( lat, lev, (u_zm[:,:,time_index])', title="u", xlabel="lat (deg N)", ylabel="z (km)", linewidth = 0);
plot_array = [plot1]
plot2 = contourf( lat, lev, (T_zm[:,:,time_index])', title="T", xlabel="lat (deg N)", ylabel="z (km)", linewidth = 0);
push!(plot_array,plot2);
plot3 = contourf( lat, lev, (v_zm[:,:,time_index])', title="sqrt(v^2)", xlabel="lat (deg N)", ylabel="z (km)", linewidth = 0);
push!(plot_array,plot3);
fig=plot(plot_array... , layout=(1, 3), size=(1200, 400) )
savefig(fig, plot_dir*"zonal_mean.pdf");
display(fig)

# ## Vertical slice
# v at lev_index
lev_index = 31
z_in_km = lev[lev_index]
v_plot = contourf( lon, lat, (v[:,:,lev_index,time_index])', title="v @ $z_in_km", xlabel="lon (deg)", ylabel="lat (deg N)", linewidth = 0);
fig=plot(v_plot, layout=(1, 1), size=(800, 400) )
savefig(fig, plot_dir*"vertical_slice.pdf");
display(fig)

# Animation
clims = (-10,10)
diag_dt_days =  (time[2] - time[1]).value / (1000*60*60*24) # get simtime

lev_index_tropos = 10
lev_tropos = lev[lev_index_tropos]

anim = @animate for t_i in 1:length(time)
    plot_array = []
    plot_zm = contourf( lat, lev, (v_zm[:,:,t_i])', title="sqrt(v^2)", xlabel="lat (deg N)", ylabel="z (km)", clims = clims, linewidth=0);
    push!(plot_array,plot_zm); 
    plot_h = contourf( lon, lat, (v[:,:,lev_index_tropos,t_i])', title="v @ $lev_tropos km", xlabel="lon (deg)", ylabel="lat (deg N)", clims = clims, linewidth=0);
    push!(plot_array,plot_h);  
    time_=time[t_i]
    plot_h = contourf( lon, lat, (v[:,:,lev_index,t_i])', title="v @ $z_in_km km @ $time_ s", xlabel="lon (deg)", ylabel="lat (deg N)", clims = clims, linewidth=0);
    push!(plot_array,plot_h);  
    plot(plot_array..., layout=(1,3), size=(1200, 400) ) 
end
mp4(anim, plot_dir*"plot_y_slice_anim.gif", fps = 7) # NB: mp4 can be more flaky than gif