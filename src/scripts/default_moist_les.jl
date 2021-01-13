using Plots

using NetCDF: ncread, ncwrite, nccreate
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
  files = [file for file in files if !occursin("AtmosCore", file)]

  ## extract grid
  z    = ncread(files[1], "z")
  time = [0.0]
  for file in files
    push!(time, ncread(file, "simtime")[1])
  end
  grid = Dict("time" => time[2:end], "z" => z)

  ## define variables of interest to aggregate
  vars = ["w", "qt", "ql", "cld_frac", "thl", "ht", "var_w", "w3", "var_qt", "var_thl", "cov_w_qt", "cov_w_thl", "w_qt_sgs", "w_ht_sgs", "cld_cover"]

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
    )
    ncwrite(data[var], combined_file, var)
  end
end

# load grid
time = ncread(combined_file, "time")
z = ncread(combined_file, "z")

# load data
vars = ["w", "qt", "ql", "cld_frac", "thl", "ht", "var_w", "w3", "var_qt", "var_thl", "cov_w_qt", "cov_w_thl", "w_qt_sgs", "w_ht_sgs", "cld_cover"]
data = Dict(var => ncread(combined_file, var) for var in vars)
println("raw data dimensions (time, height): ", size(data["w"]))

# create time mean data
avg_start_ind = 60 # for removing the spinup time
data_time_mean = Dict(k => mean(v[avg_start_ind:end, :], dims=1)[end, :] for (k, v) in data)
println("time-averaged data dimensions (height): ", size(data_time_mean["w"]))

## Plot time means
p1 = plot(z, data_time_mean["w"], xlabel="w_time_mean", ylabel="z (km)")
p2 = plot(z, data_time_mean["qt"], xlabel="qt_time_mean", ylabel="z (km)")
p3 = plot(z, data_time_mean["ql"], xlabel="ql_time_mean", ylabel="z (km)")
p4 = plot(z, data_time_mean["cld_frac"], xlabel="cld_frac_time_mean", ylabel="z (km)")
p5 = plot(z, data_time_mean["thl"], xlabel="thl_time_mean", ylabel="z (km)")
p6 = plot(z, data_time_mean["ht"], xlabel="ht_time_mean", ylabel="z (km)")
fig = plot(p1, p2, p3, p4, p5, p6, layout=(3, 2), size=(1500, 800))
savefig(fig, string(analysis_folder, "time_means.png"))

# Plot variance and covariances
p1 = plot(z, data_time_mean["var_w"], xlabel="w_time_mean", ylabel="z (km)")
p2 = plot(z, data_time_mean["w3"], xlabel="w3_time_mean", ylabel="z (km)")
p3 = plot(z, data_time_mean["var_qt"], xlabel="var_qt_time_mean", ylabel="z (km)")
p4 = plot(z, data_time_mean["var_thl"], xlabel="var_thl_frac_time_mean", ylabel="z (km)")
p5 = plot(z, data_time_mean["cov_w_qt"], xlabel="cov_w_qt_time_mean", ylabel="z (km)")
p6 = plot(z, data_time_mean["cov_w_thl"], xlabel="cov_w_thl_time_mean", ylabel="z (km)")
p7 = plot(z, data_time_mean["w_qt_sgs"], xlabel="w_qt_sgs_time_mean", ylabel="z (km)")
p8 = plot(z, data_time_mean["w_ht_sgs"], xlabel="w_ht_sgs_time_mean", ylabel="z (km)")
fig = plot(p1, p2, p3, p4, p5, p6, p7, p8, layout=(4, 2), size=(2000, 800))
savefig(fig, string(analysis_folder, "covariances.png"))

# Plot time series
p1 = plot(time/3600., data["cld_cover"], xlabel="Time (hour)", ylabel="cld_cover")
fig = plot(p1, size=(1000, 400))
savefig(fig, string(analysis_folder, "time_series.png"))

