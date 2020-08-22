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

# Setup run-time enviromnent
ENV["GKSwstype"] = "100"

# Select the variable to plot
var_name_list = Any["u","thd"];
plot_anomaly = true;
nan_fill_value = 0
t_spinup = 1
level_index=2


# Specify needed directories and filenames: these will be replaced automatically by the bash run script or can be modified manually
CLIMA_ANALYSIS = "/central/scratch/elencz/output/gcm_ci/analysis"
CLIMA_NETCDF = "/central/scratch/elencz/output/hs_bmark_d/netcdf/copies";
CLIMA_LOGFILE = "/central/scratch/elencz/output/hs_bmark_d/log/experiments_performance_log";
RUNNAME = "hs_bmark_d";

# Get the current and previous  GCM netcdf file names in the CLIMA_NETCDF directory
fnames = filter(x -> occursin("AtmosGCM", x), readdir( CLIMA_NETCDF ) );

# Aggregate data in output into a multi-file dataset
nexp = size(fnames)
nvar = size(var_name_list)
nrows = nvar[1]
ncols = nexp[1]


# zonal and time mean views
lat, time, dummy= get_timezonal_mean( "$CLIMA_NETCDF/"fnames[1], var_name_list[1], t_spinup, nan_fill_value);
clims = ( get_min_max(dummy) )


plot_array = Any[]; 
for i in 1:nexp[1]
  for n in 1:nvar[1]
    title = var_name_list[n]
    lat, z , vs = get_timezonal_mean( "$CLIMA_NETCDF/"fnames[i], var_name_list[n], t_spinup, nan_fill_value);
    if i ==1
      title = title*" change" # could add name of commit here
      lat, z , vs_curr = get_timezonal_mean( "$CLIMA_NETCDF/"fnames[i+1], var_name_list[n], t_spinup, nan_fill_value);
      vs = vs_curr - vs; 
    end
    one_plot = contourf( lat, z, vs[1,:,:,1], title = title, ylabel="height (m)", xlabel="latitide (deg N)", clims = clims);
    push!(plot_array,one_plot); # make a plot and add it to the plot_array
  end
end

fig=plot(plot_array... , layout=(nrows,ncols), size=(1000, 400) )
savefig(fig, string("$CLIMA_ANALYSIS/plot_timezonal_mean.pdf"));
display(fig)

# Animation
var_names_an = ["v","vor"]
altitude_index = 7
var_array = Any[]; # can type this more strictly
t_nos = Any[];
diag_dts=Any[]
time, z, lat, lon, dummy = get_var( "$CLIMA_NETCDF/"fnames[1], var_name_list[1], t_spinup, nan_fill_value)
clims = ( get_min_max(dummy) )
for i in 1:nexp[1]
  for n in 1:nvar[1]
    time, z, lat, lon, data = get_var( "$CLIMA_NETCDF/"fnames[i], var_name_list[n], t_spinup, nan_fill_value);
    push!(var_array,data); # make a plot and add it to the plot_array
    push!(t_nos,size(time)[1]); # make a plot and add it to the plot_array
    diag_dt_days =  (time[2] - time[1]).value / (1000*60*60*24) # get simtime
    push!(diag_dts,diag_dt_days);
  end
end
max_time_no=maximum(t_nos) # number of timesteps of the longest running experiment

anim = @animate for t_i in 2:max_time_no
  plot_array = Any[]; # can type this more strictly
  for i in 1:nexp[1]
    for n in 1:nvar[1]
      var_array_pad = PaddedView(nan_fill_value, var_array[i], (size(lon)[1], size(lat)[1], size(z)[1], max_time_no) );   
      vs = var_array_pad[:,:,altitude_index,t_i]
      title = var_name_list[n]
      if i ==1
        title = title*" last" # could add name of commit here 
      end
      one_plot = contourf( lon, lat, vs', title = title, xlabel="lon (deg)", ylabel="lat (deg N)", clims = clims);
      push!(plot_array,one_plot); # make a plot and add it to the plot_array
    end
  end                        
    plot(plot_array..., layout=(nrows,ncols), size=(1000, 400) ) 
end
mp4(anim, string("$CLIMA_ANALYSIS/plot_horizontal_slice_anim.mp4"), fps = 5) # hide
#display(anim)


# get the longer sim time of the two experiments
var_array = Any[]; # can type this more strictly
t_nos = Any[];
time, z, lat, lon, dummy = get_var( "$CLIMA_NETCDF/"fnames[1], var_name_list[1], t_spinup, nan_fill_value)
clims = ( get_min_max(dummy) )
for i in 1:nexp[1]
  time, z, lat, lon, data = get_var( "$CLIMA_NETCDF/"fnames[i], var_name_list[1], t_spinup, nan_fill_value);
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
  rho_mean = mean( rho[:,:,:,:]  , dims=1)
  uPR = u .- mean( rho .* u[:,:,:,:]  , dims=1) ./ rho_mean
  vPR = v .- mean( rho .* v[:,:,:,:]  , dims=1) ./ rho_mean
  EKE = 0.5 .* (uPR .^ 2 + vPR .^ 2 )
  push!(KE_array,KE); 
  push!(EKE_array,EKE); 
  push!(rho_array,rho); 
  push!(t_nos,size(time)[1]); # make a plot and add it to the plot_array
end


# Individual plots
plot_array = Any[];
for i in 1:nexp[1]
  title = "KE_EKE"
  if i ==1
    title = title*" last" # could add name of commit here
  end
  time_r = collect(1:1:t_nos[i]); 
  KEr = mean(KE_array[i] .* rho_array[i],dims=(1,2,3))[1,1,1,:]
  EKEr = mean(EKE_array[i] .* rho_array[i],dims=(1,2,3))[1,1,1,:]
  rhor = mean(rho_array[i],dims=(1,2,3))[1,1,1,:]
  one_plot = plot( time_r*diag_dts[i],[ KEr ./ rhor , EKEr ./ rhor ], label = ["KE" "EKE"], title = title, xlims = (0,110) )
  push!(plot_array,one_plot );
end

# Plot and save the array of plots
fig=plot(plot_array... ,  layout=(1,ncols), size=(3000, 1200) )
savefig(fig, string("$CLIMA_ANALYSIS/kinetic_energy_spinup.pdf"));
display(fig)

# Print performance info
fl=readdlm("$CLIMA_LOGFILE")  # ensure heading don't contain spaces
print((fl[1,:]))
#pretty_table(fl[2:end,2:end],l[1,2:end])
print_table = "true"

if print_table =="true"
  header = [ "driver_name", "compl_days", "wall_time(s)"]
  table_data =Array{String}(undef, (nexp[1]+1), size(header)[1]);
  table_data[1,:] = header
  for i in 2:nexp[1]+1
    driver = fl[i,1]
    #table_data[i,1] = split(driver,"n_horz_")[2][1:2]
    #table_data[i,2] = split(driver,"poly_order_")[2][1:2] 
    root = split((split(driver,"hier_")[end]),".jl")[1]
    fname = filter(x -> occursin(root, x), readdir( CLIMA_NETCDF ) );
    
    time, z, lat, lon, dummy = get_var( "$CLIMA_NETCDF/"fname, var_name_list[1], t_spinup, nan_fill_value);
    #diag_dt_days =  Float64(Dates.value( Dates.Second(time[2] - time[1]) ) ) / Float64(1000*60*60*24) 
    
    #table_data[i,3] = string(round( size(time)[1]*diag_dt_days ,digits=2)) # sim days #string(t_nos[i-1]) # no copleted t steps    
    #table_data[i,4] = string(fl[i,3]) # wall time
    #table_data[i,5] = split(driver,"hyperFT_")[2][1:2]
    #table_data[i,6] = string(fl[i,8]) # CFL
    #table_data[i,7] = string(round(diag_dt_days,digits=2))
    table_data[i,1] = string(root) # driver name
    #@info @sprintf("""some parameter info: %s""", diag_dt_days)
    #table_data[i,2] = string( diag_dt_days )
    #table_data[i,2] = string(round( size(time)[1]*diag_dt_days ,digits=2)) # sim days
    table_data[i,3] = string(fl[i,3]) # wall time
  end
end



# Make the table
pretty_table(table_data[2:end,1:end],table_data[1,1:end])


# TODO
# energy spectra
# axial angular momentum conservation
#
#
