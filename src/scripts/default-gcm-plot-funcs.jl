# Load modules
using Plots
using NCDatasets
using Statistics: mean
using DelimitedFiles
using PrettyTables
using PaddedViews
using Dates


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

function get_lonslice_vslice(file_name, var_name, t_spinup, lev_i, lon_i,nan_fill_value);
    ds = NCDataset(file_name, "r");
    lon = ds["long"][:];
    lat = ds["lat"][:];
    z = ds["level"][:] / 1e3; # height in kilometers
    time = ds["time"][:];  # time
    var = ds[var_name][:];
    var=var[:, :, :, t_spinup:end]; # cut out the spinup;
    data_time_mean_vslice = (var[lon_i,:,lev_i,:]); # create statistics
    replace!(data_time_mean_vslice, NaN=>nan_fill_value)
    return lat, time, data_time_mean_vslice
    none
end

function get_min_max(var);
    vmax = maximum(filter(!isnan,var))
    vmin = minimum(filter(!isnan,var))
    return vmin,vmax
    none
end

# Setup run-time enviromnent
ENV["GKSwstype"] = "100"

# Select the variable to plot
var_name = "u";
plot_anomaly = false;
nan_fill_value = 0
t_spinup = 1
level_index=2


# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_ANALYSIS = "/central/scratch/elencz/output/hs_bmark_np/analysis/";
CLIMA_NETCDF = "/central/scratch/elencz/output/hs_bmark_d/netcdf/copies";
CLIMA_LOGFILE = split(CLIMA_ANALYSIS, "analysis")[1]*"/log/experiments_performance_log";
RUNNAME = "hs_bmark_d";

var_sname_1 = "hyper"
var_sname_2 = "cfl"

var_code_1 = "hyperFT_"
var_code_2 = "CFL_FT"

nrows = 5
ncols = 5


# Get all netcdf file names with a specified string in the CLIMA_NETCDF directory
fnames = filter(x -> occursin("AtmosGCMDefault", x), readdir( CLIMA_NETCDF ) );

# Aggregate data in output into a multi-file dataset
nexp = size(fnames)

# Customise shorter exp names (TODO: automate this section)
exp_names = Array{String}(undef, nexp[1]);

for i in 1:nexp[1]
  driver = fnames[i]
  exp_names[i] = var_sname_1 * split(split(driver,var_code_1)[2],"_")[1] * "_" *  var_sname_2 * split(split(driver,var_code_2)[2],"_")[1]
end

# Hovmoller
var_name = "u"
lon_index = 10
lat, time, dummy= get_lonslice_vslice( "$CLIMA_NETCDF/"fnames[2], var_name, 1, level_index, lon_index, nan_fill_value);
clims = ( get_min_max(dummy[:, :]) )

plot_array = Any[]; 
diag_dts=Any[]
for i in 1:nexp[1]
  lat, time, vs = get_lonslice_vslice( "$CLIMA_NETCDF/"fnames[i], var_name, 1, level_index, lon_index, nan_fill_value);
  time_r = collect(1:1:size(time)[1]);  
  diag_dt_days =  (time[2] - time[1]).value / (1000*60*60*24) 
  one_plot = contourf( time_r .* diag_dt_days, lat, vs, title = exp_names[i], xlabel="time", ylabel="lat (deg N)", clims = clims);
  push!(plot_array,one_plot); # make a plot and add it to the plot_array
  push!(diag_dts,diag_dt_days);
end

fig=plot(plot_array... , layout=(nrows,ncols), size=(3000, 1200) )
savefig(fig, string("$CLIMA_ANALYSIS/plot_$var_name","_hovmoller_sens.pdf"));
display(fig)

# Animation
altitude_index = 7
var_array = Any[]; # can type this more strictly
t_nos = Any[];
time, z, lat, lon, dummy = get_var( "$CLIMA_NETCDF/"fnames[2], var_name, t_spinup, nan_fill_value)
clims = ( get_min_max(dummy) )
for i in 1:nexp[1]
  time, z, lat, lon, data = get_var( "$CLIMA_NETCDF/"fnames[i], var_name, t_spinup, nan_fill_value);
  push!(var_array,data); # make a plot and add it to the plot_array
  push!(t_nos,size(time)[1]); # make a plot and add it to the plot_array
end
max_time_no=maximum(t_nos) # number of timesteps of the longest running experiment

anim = @animate for t_i in 2:max_time_no
  plot_array = Any[]; # can type this more strictly
  for i in 1:nexp[1]
    var_array_pad = PaddedView(nan_fill_value, var_array[i], (size(lon)[1], size(lat)[1], size(z)[1], max_time_no) );
    vs = var_array_pad[:,:,altitude_index,t_i]
    one_plot = contourf( lon, lat, vs', title = exp_names[i], xlabel="lon (deg)", ylabel="lat (deg N)", clims = clims);
    push!(plot_array,one_plot); # make a plot and add it to the plot_array
  end                        
    plot(plot_array..., layout=(nrows,ncols), size=(3000, 1200) ) 
end
mp4(anim, string("$CLIMA_ANALYSIS/plot_$var_name","_lat_lon_sens_anim.mp4"), fps = 5) # hide
#display(anim)


# Kinetic energy
var_array = Any[]; # can type this more strictly
t_nos = Any[];
time, z, lat, lon, dummy = get_var( "$CLIMA_NETCDF/"fnames[2], var_name, t_spinup, nan_fill_value)
clims = ( get_min_max(dummy) )
for i in 1:nexp[1]
  time, z, lat, lon, data = get_var( "$CLIMA_NETCDF/"fnames[i], var_name, t_spinup, nan_fill_value);
  push!(var_array,data); # make a plot and add it to the plot_array
  push!(t_nos,size(time)[1]); # make a plot and add it to the plot_array
end
max_time_no=maximum(t_nos) # number of timesteps of the longest running experiment


# Get KE and EKE of all experiments
KE_array = Any[]; 
EKE_array = Any[];
rho_array = Any[];
t_nos = Any[];
for i in 1:nexp[1]
  time, z, lat, lon, u = get_var( "$CLIMA_NETCDF/"fnames[i], "u", t_spinup, nan_fill_value);
  time, z, lat, lon, v = get_var( "$CLIMA_NETCDF/"fnames[i], "v", t_spinup, nan_fill_value);
  time, z, lat, lon, rho = get_var( "$CLIMA_NETCDF/"fnames[i], "rho", t_spinup, nan_fill_value);
  KE = 0.5 * (u .^ 2 + v .^ 2)
  uPR = u .- mean( u[:,:,:,:]  , dims=1)
  vPR = v .- mean( v[:,:,:,:]  , dims=1)
  EKE = 0.5 .* (uPR .^ 2 + vPR .^ 2 )
  push!(KE_array,KE); 
  push!(EKE_array,EKE); 
  push!(rho_array,rho); 
  push!(t_nos,size(time)[1]); # make a plot and add it to the plot_array
end


# Individual plots
plot_array = Any[];
for i in 1:nexp[1]
  time_r = collect(1:1:t_nos[i]); 
  KEr = mean(KE_array[i] .* rho_array[i],dims=(1,2,3))[1,1,1,:]
  EKEr = mean(EKE_array[i] .* rho_array[i],dims=(1,2,3))[1,1,1,:]
  rhor = mean(rho_array[i],dims=(1,2,3))[1,1,1,:]
  one_plot = plot( time_r*diag_dts[i],[ KEr ./ rhor , EKEr ./ rhor ], label = ["KE" "EKE"], title = exp_names[i], xlims = (0,110) )
  push!(plot_array,one_plot );
end

# Plot and save the array of plots
fig=plot(plot_array... ,  layout=(nrows,ncols), size=(3000, 1200) )
savefig(fig, string("$CLIMA_ANALYSIS/kinetic_energy.pdf"));
display(fig)

# Print performance info
fl=readdlm("$CLIMA_LOGFILE")  # ensure heading don't contain spaces
print((fl[1,:]))
#pretty_table(fl[2:end,2:end],l[1,2:end])

# Make an array for table
header = [ "n_horz", "poly_order", "compl_days", "wall_time(s)", "t_hyper", "CFL", "dt(days)"]
table_data =Array{String}(undef, (nexp[1]+1), size(header)[1]);
table_data[1,:] = header
for i in 2:nexp[1]+1
  driver = fl[i,1]
  table_data[i,1] = split(driver,"n_horz_")[2][1:2]
  table_data[i,2] = split(driver,"poly_order_")[2][1:2]
  root = split((split(driver,"heldsuarez_")[2]),".jl")[1]
  fname = filter(x -> occursin(root, x), readdir( CLIMA_NETCDF ) );
  lat, time, vs = get_lonslice_vslice( "$CLIMA_NETCDF/"fname[1], "u", 1, level_index, lon_index, nan_fill_value);
  diag_dt_days =  (time[2] - time[1]).value / (1000*60*60*24) 
  table_data[i,3] = string(round( size(time)[1]*diag_dt_days ,digits=2)) # sim days #string(t_nos[i-1]) # no copleted t steps    
  table_data[i,4] = string(fl[i,3]) # wall time
  table_data[i,5] = split(driver,"hyperFT_")[2][1:2]
  table_data[i,6] = string(fl[i,8]) # CFL
  table_data[i,7] = string(round(diag_dt_days,digits=2))
end

# Make the table
pretty_table(table_data[2:end,1:end],table_data[1,1:end])

