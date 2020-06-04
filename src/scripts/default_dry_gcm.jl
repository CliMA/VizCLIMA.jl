using Plots

using NCDatasets
using Statistics: mean

# data folders
data_folder = "/central/scratch/bischtob/gcm_dcmip31/netcdf/"
combined_file = "/central/scratch/bischtob/gcm_dcmip31/netcdf/combined.nc"
analysis_folder = "/central/scratch/bischtob/gcm_dcmip31/analysis/"

# check if combined file extist, otherwise create it
if !isfile(combined_file)
    files = sort(readdir(data_folder, join=true))
    ds_out = NCDataset(combined_file, "c")

    ## Set up two distinct variable classes as they have
    ## different sizes
    ds =   ds = NCDataset(files[1], "r")
    vars_grid = ["long", "lat", "level"]
    vars_physical = setdiff(keys(ds), vars_grid)

    ## Dimensions from grid variables
    for var in vars_grid
        ds_out.dim[var] = length(ds[var])
    end

    ## Declare & fill grid variables
    for var in vars_grid
        ncvar = defVar(ds_out, var, eltype(ds[var]), (var,), attrib=ds[var].attrib)
        ncvar[:] = ds[var][:]
    end

    ## Read and aggregate physical variables
    var_dict = Dict(var => [] for var in vars_physical)
    for file in files
        ds_tmp = NCDataset(file, "r")
        for var in vars_physical
            push!(var_dict[var], ds_tmp[var][:])
        end
    end
    var_dict = Dict(var => vcat(var_dict[var]...) for var in vars_physical)

    ## Set time dimension, declare & fill time variable
    var = "time"
    ds_out.dim[var] = length(var_dict[var])
    ncvar = defVar(ds_out, var, eltype(ds[var]), (var,), attrib=ds[var].attrib)
    ncvar[:] = var_dict[var]

    ## Declare & fill physical variables
    for var in setdiff(vars_physical, ["time"])
        ncvar = defVar(ds_out, var, eltype(ds[var]), ("time", "long", "lat", "level"), attrib=ds[var].attrib)
        ncvar[:] = var_dict[var]
    end
end

# load grid
ds = NCDataset(combined_file, "r")

lon = ds["long"][:]
lat = ds["lat"][:]
z = ds["level"][:] / 1e3 # height in kilometers
time = ds["time"][:] / 86400 # time in days
u = ds["u"][:]
v = ds["v"][:]
w = ds["w"][:]
ρ = ds["rho"][:]
T = ds["temp"][:]
p = ds["pres"][:]
θ = ds["thd"][:]
e_t = ds["et"][:]
e_i = ds["ei"][:]
h_t = ds["ht"][:]
h_i = ds["hi"][:]
ω = ds["vort"][:]
data = Dict("u" => u, "v" => v, "w" => w, "T" => T, "θ" => θ)
nothing
println("dimensions: ", size(T))

# cut out the spinup
start = 1
data = Dict(k => v[start:end, :, :, :] for (k, v) in data);

# create statistics
data_time_mean = Dict(k => mean(v, dims=1)[1, :, :, :] for (k, v) in data)
data_zonal_mean = Dict(k => mean(v, dims=2)[:, 1, :, :] for (k, v) in data)
data_time_zonal_mean = Dict(k => mean(v, dims=1)[1, :, :] for (k, v) in data_time_mean)
data_time_zonal_deviations = Dict(k1 => v1 .- reshape(v2[:, :, :, :], (length(time), 1, length(lat), length(z))) for ((k1, v1), (k2, v2)) in zip(data, data_zonal_mean))
data_zonal_mean_covariances = Dict(string(k1, k2) => mean(v1 .* v2, dims=2)[:, 1, :, :] for (k1, v1) in data_time_zonal_deviations for (k2, v2) in data_time_zonal_deviations)
data_time_zonal_mean_covariances = Dict(string(k1, k2) => mean(v1 .* v2, dims=(1, 2))[1, 1, :, :] for (k1, v1) in data_time_zonal_deviations for (k2, v2) in data_time_zonal_deviations)

# plot time and zonal mean
nlev = 20
ylab = "height (km)"
ylim = (0, 30)
cg = cgrad([:blue, :white, :red])
cd = cgrad([:blue, :white, :red])
p1 = contourf(lat, z, data_time_zonal_mean["u"]', ylim=ylim, ylabel=ylab, color=cg, levels=LinRange(-35, 35, nlev), linewidth=0)
contour!(p1, lat, z, data_time_zonal_mean["u"]', ylim=ylim, levels=[0.0], linewidth=2, color=:black)
p2 = contourf(lat, z, data_time_zonal_mean["v"]', ylim=ylim, color=cg, levels=LinRange(-1, 1, nlev), linewidth=0)
contour!(p2, lat, z, data_time_zonal_mean["v"]', ylim=ylim, levels=[0.0], linewidth=2, color=:black)
p3 = contourf(lat, z, data_time_zonal_mean_covariances["uv"]', ylim=ylim, ylabel=ylab, color=cg, levels=LinRange(-70, 70, nlev), linewidth=0)
contour!(p3, lat, z, data_time_zonal_mean_covariances["uv"]', ylim=ylim, levels=[0.0], linewidth=2, color=:black)
p4 = contourf(lat, z, data_time_zonal_mean_covariances["vT"]', ylim=ylim, color=cg, levels=LinRange(-30, 30, nlev), linewidth=0)
contour!(p4, lat, z, data_time_zonal_mean_covariances["vT"]', ylim=ylim, levels=[0.0], linewidth=2, color=:black)
p5 = contourf(lat, z, data_time_zonal_mean["T"]', ylim=ylim, xlabel="latitude", ylabel=ylab, color=cd, levels=LinRange(273.15-100, 273.13+100, nlev), linewidth=0)
p6 = contourf(lat, z, data_time_zonal_mean_covariances["TT"]', ylim=ylim, xlabel="latitude", color=cd, levels=LinRange(0, 45, nlev), linewidth=0)
fig = plot(p1, p2, p3, p4, p5, p6, layout=(3, 2), size=(3000, 3000), title=["u (m/s)" "v (m/s)" "cov(u,v) (m^2/s^2)" "cov(v,T) (Km /s^2)" "T (K)" "var(T) (K)"])
savefig(fig, string(analysis_folder, "time_zonal_mean.pdf"))

# plot vertical slices
p1 = plot(data_time_zonal_mean["u"][[5, 10, end-4], :]', z, xlabel="Velocity (m/s)", ylabel="z (km)", label=["Southern hemisphere" "Equator" "Northern hemisphere"])
p2 = plot(data_time_zonal_mean["v"][[5, 10, end-4], :]', z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p3 = plot(data_time_zonal_mean["w"][[5, 10, end-4], :]', z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p4 = plot(data_time_zonal_mean["T"][[5, 10, end-4], :]', z, xlabel="Temperature (K)", ylabel="z (km)", label=false)
fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(2000, 1600), title=["Zonal & time mean zonal velocity (m/s)" "Zonal & time mean meridional velocity (m/s)" "Zonal & time mean vertical velocity (m/s)" "Temperature (K)"])
savefig(fig, string(analysis_folder, "time_zonal_mean_vertical_slice.pdf"))

# change between end of simulation and beginning of simulation
p1 = plot(data_zonal_mean["u"][end, 10, :], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p2 = plot(data_zonal_mean["v"][end, 10, :], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p3 = plot(data_zonal_mean["w"][end, 10, :], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p4 = plot(data_zonal_mean["T"][end, 10, :]-data_zonal_mean["T"][1, 10, :], z, xlabel="Temperature (K)", ylabel="z (km)", label=false)
fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(2000, 1600), title=["Zonal-mean zonal velocity change (m/s)" "Zonal-mean meridional velocity change (m/s)" "Zonal-mean vertical velocity change (m/s)" "Zonal-mean temperature change (K)"])
savefig(fig, string(analysis_folder, "zonal_mean_change_vertical_slice.pdf"))

# change between end of simulation and beginning of simulation
p1 = plot(data_zonal_mean["u"][end, :, 10], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p2 = plot(data_zonal_mean["v"][end, :, 10], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p3 = plot(data_zonal_mean["w"][end, :, 10], z, xlabel="Velocity (m/s)", ylabel="z (km)", label=false)
p4 = plot(data_zonal_mean["T"][end, :, 10]-data_zonal_mean["T"][1, :, 10], z, xlabel="Temperature (K)", ylabel="z (km)", label=false)
fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(2000, 1600), title=["Zonal-mean zonal velocity change (m/s)" "Zonal-mean meridional velocity change (m/s)" "Zonal-mean vertical velocity change (m/s)" "Zonal-mean temperature change (K)"])
savefig(fig, string(analysis_folder, "zonal_mean_change_vertical_slice.png"))

# plot horizontal slices
p1 = plot(data_time_zonal_mean["u"][:, [1, 5, 15]], lat, xlabel="Velocity (m/s)", ylabel="latitude", label=["Surface" "Troposphere" "Stratosphere"])
p2 = plot(data_time_zonal_mean["v"][:, [1, 5, 15]], lat, xlabel="Velocity (m/s)", ylabel="latitude", label=false)
p3 = plot(data_time_zonal_mean["w"][:, [1, 5, 15]], lat, xlabel="Velocity (m/s)", ylabel="latitude", label=false)
p4 = plot(data_time_zonal_mean["T"][:, [1, 5, 15]], lat, xlabel="Temperature (K)", ylabel="latitude", label=false)
fig = plot(p1, p2, p3, p4, layout=(2, 2), size=(2000, 1600), title=["Zonal & time mean zonal velocity (m/s)" "Zonal & time mean meridional velocity (m/s)" "Zonal & time mean vertical velocity (m/s)" "Temperature (K)"])
savefig(fig, string(analysis_folder, "time_zonal_mean_horizontal_slice.pdf"))

# plot kinetic energy
ke = sum(data_zonal_mean["u"].^2 + data_zonal_mean["v"].^2 + data_zonal_mean["w"].^2, dims=(2, 3, 4))[:];
fig = plot(time[start:end], ke, size=(2500, 666), xlabel="time", ylabel="squared norm of velocity vector")
savefig(fig, string(analysis_folder, "kinetic_energy_time_series.pdf"))
