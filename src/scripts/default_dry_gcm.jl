using Plots

using NetCDF: nccreate, ncread, ncwrite
using Statistics: mean

# data folders
data_folder = DATA_FOLDER
combined_file = COMBINE_FILE 
analysis_folder = ANALYSIS_FOLDER 

# check if combined file extist, otherwise create it
if !isfile(combined_file)
  ## get all the filenames in the data directory
  files = sort(readdir(data_folder, join=true))
  files = [file for file in files if occursin(".nc", file)]
  files = [file for file in files if ~occursin("aux", file)]
  
  ## extract grid
  lat  = ncread(files[1], "lat")
  lon  = ncread(files[2], "long")
  z    = ncread(files[2], "rad") .- 6370000
  time = [0.0]
  for file in files
    push!(time, ncread(file, "simtime")[1])
  end
  grid = Dict("time" => time[2:end], "lat" => lat, "lon" => lon, "z" => z)
  
  ## define variables of interest to aggregate
  vars = ["ρ", "ρu[1]", "ρu[2]", "ρu[3]", "ρe"]

  ## read and aggregate variables of interest from files
  data = Dict(var => [] for var in vars)
  for file in files
    for var in vars
      temp = ncread(file, var)
      temp = reshape(temp, (1, size(temp)...))
      push!(data[var], temp)
    end
  end
  data = Dict(var => vcat(data[var]...) for var in vars)
  
  ## write data to disk as combined file
  for var in vars
    nccreate(
      combined_file, 
      var, 
      "time", grid["time"],
      "z", grid["z"], 
      "lat", grid["lat"],
      "lon", grid["lon"],
    )
    ncwrite(data[var], combined_file, var)
  end
end

# load grid
time = ncread(combined_file, "time")
z = ncread(combined_file, "z")
lat = ncread(combined_file, "lat")
lon = ncread(combined_file, "lon")

# load data
ρ = ncread(combined_file, "ρ")
u = ncread(combined_file, "ρu[3]") ./ ρ
v = ncread(combined_file, "ρu[2]") ./ ρ
w = ncread(combined_file, "ρu[1]") ./ ρ
e = ncread(combined_file, "ρe") ./ ρ
data = Dict('u' => u, 'v' => v, 'w' => w, 'e' => e)
println("raw data dimensions (time, height, lat, lon): ", size(e))

# create time mean data
avg_start_ind = 60 # for removing the spinup time
data_time_mean = Dict(k => mean(v[avg_start_ind:end, :, :, :], dims=1)[end, :, :, :] for (k, v) in data)
println("time-averaged data dimensions (height, lat, lon): ", size(data_time_mean['e']))

# create zonal mean data
data_zonal_mean = Dict(k => mean(v, dims=4)[:, :, :, end] for (k, v) in data)
println("zonally-averaged data dimensions (time, height, lat): ", size(data_zonal_mean['e']))

# create time and zonal mean data
data_time_zonal_mean = Dict(k => mean(v, dims=3)[:, :, end] for (k, v) in data_time_mean)
println("time- and zonally-averaged data dimensions (height, lat): ", size(data_time_zonal_mean['e']))

# Set up plotting backend
Plots.PyPlotBackend()

# plot time and zonal mean
p1 = contourf(lat, z, data_time_zonal_mean['u'], xlabel="latitude", ylabel="z (km)", color=:balance, levels=10, linewidth=0)
p2 = contourf(lat, z, data_time_zonal_mean['v'], xlabel="latitude", ylabel="z (km)", color=:balance, levels=10, linewidth=0)
p3 = contourf(lat, z, data_time_zonal_mean['w'], xlabel="latitude", ylabel="z (km)", color=:balance, levels=10, linewidth=0)
p4 = contourf(lat, z, data_time_zonal_mean['e'], xlabel="latitude", ylabel="z (km)", color=:thermal, levels=10, linewidth=0)
fig = plot(p1, p2, p3, p4, layout=4, size=(1500, 800), title=["Zonal & time mean zonal velocity (m/s)" "Zonal & time mean meridional velocity (m/s)" "Zonal & time mean vertical velocity (m/s)" "Total energy (J)"])
savefig(fig, string(analysis_folder, "time_zonal_mean.png"))

# plot vertical slices
p1 = plot(data_time_zonal_mean['u'][:, [5, 10, end-4]], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=["Southern hemisphere" "Equator" "Northern hemisphere"])
p2 = plot(data_time_zonal_mean['v'][:, [5, 10, end-4]], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p3 = plot(data_time_zonal_mean['w'][:, [5, 10, end-4]], z, xlabel="Velocity (m/s)", ylabel="z (km)")
p4 = plot(data_time_zonal_mean['e'][:, [5, 10, end-4]], z, xlabel="Total energy (J)", ylabel="z (km)")
fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(1000, 800), title=["Zonal & time mean zonal velocity (m/s)" "Zonal & time mean meridional velocity (m/s)" "Zonal & time mean vertical velocity (m/s)" "Total energy (J)"])
savefig(fig, string(analysis_folder, "time_zonal_mean_vertical_slice.png"))

# plot horizontal slices
p1 = plot(data_time_zonal_mean['u'][[1, 5, 15], :]', lat, xlabel="Velocity (m/s)", ylabel="latitude", label=["Surface" "Troposphere" "Stratosphere"])
p2 = plot(data_time_zonal_mean['v'][[1, 5, 15], :]', lat, xlabel="Velocity (m/s)", ylabel="latitude", label=false)
p3 = plot(data_time_zonal_mean['w'][[1, 5, 15], :]', lat, xlabel="Velocity (m/s)", ylabel="latitude", label=false)
p4 = plot(data_time_zonal_mean['e'][[1, 5, 15], :]', lat, xlabel="Total energy (J)", ylabel="latitude", label=false)
fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(1000, 800), title=["Zonal & time mean zonal velocity (m/s)" "Zonal & time mean meridional velocity (m/s)" "Zonal & time mean vertical velocity (m/s)" "Total energy (J)"])
savefig(fig, string(analysis_folder, "time_zonal_mean_horizontal_slice.png"))

