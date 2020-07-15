using Plots
using ColorSchemes
using NetCDF: ncread, ncwrite, nccreate

# data folders
data_folder = "/Users/ajaruga_new/clones/ClimateMachine.jl/output/"
analysis_folder = "/Users/ajaruga_new/clones/ClimateMachine.jl/output/"

# get the state and aux files in the data directory
files = sort(readdir(data_folder))
files = [file for file in files if occursin(".nc", file)]
file_s = [file for file in files if occursin("State", file)]
file_a = [file for file in files if occursin("Aux", file)]

file_s = string(data_folder, file_s[1])
file_a = string(data_folder, file_a[1])

# extract grid
z = ncread(file_s, "z") / 1e3
x = ncread(file_s, "x") / 1e3
t = ncread(file_s, "time")

# state variables of interest
var_s = ["ρ", "ρu[1]", "ρu[2]", "ρu[3]", "ρe",
         "ρq_tot", "ρq_liq", "ρq_ice", "ρq_rai", "ρq_sno"
        ]

var_a = ["p", "u", "w", "q_tot", "q_vap", "q_liq", "q_ice", "q_rai", "q_sno",
         "e_tot", "e_kin", "e_pot", "e_int", "T", "S_liq", "S_ice", "RH",
         "rain_w", "snow_w", "src_cloud_liq", "src_cloud_ice",
         "src_rain_acnv", "src_snow_acnv", "src_liq_rain_accr",
         "src_liq_snow_accr", "src_ice_snow_accr", "src_ice_rain_accr",
         "src_snow_rain_accr", "src_rain_accr_sink", "src_rain_evap",
         "src_snow_subl", "src_snow_melt", "flag_cloud_liq", "flag_cloud_ice",
         "flag_rain", "flag_snow", "ρe_init", "ρq_tot_init"]

data_s = Dict(var => ncread(file_s, var) for var in var_s)
data_a = Dict(var => ncread(file_a, var) for var in var_a)
#(x, y, z, t)
#@info(size(data_a["w"]))

time_idx = 5
y_idx    = 5

ylab = "z [km]"
xlab = "x [km]"
nlev = 20

# quicklook at general conditions
p1 = contourf(x, z, transpose(data_a["u"][:,  y_idx, :, time_idx]),     ylabel=ylab,              levels=nlev, title="u [m/s]", color=:curl)
p2 = contourf(x, z, transpose(data_a["w"][:,  y_idx, :, time_idx]),                               levels=nlev, title="w [m/s]", color=:curl)
p3 = contourf(x, z, transpose(data_a["T"][:,  y_idx, :, time_idx]),     ylabel=ylab,              levels=nlev, title="T [K]", color=:haline)
p4 = contourf(x, z, transpose(data_a["RH"][:, y_idx, :, time_idx]),                               levels=nlev, title="RH [-]", color=:haline)
p5 = contourf(x, z, transpose(data_s["ρ"][:,  y_idx, :, time_idx]),     ylabel=ylab, xlabel=xlab, levels=nlev, title="rho [kg/m3]", color=:haline)
p6 = contourf(x, z, transpose(data_a["p"][:,  y_idx, :, time_idx])/1e2,              xlabel=xlab, levels=nlev, title="p [hPa]", color=:haline)
fig = plot(p1, p2, p3, p4, p5, p6, layout=(3, 2), size=(1500, 1000))
savefig(fig, string(analysis_folder, "quicklook.pdf"))

# energies and terminal velocities
p1 = contourf(x, z, transpose(data_a["e_tot"][:, y_idx, :, time_idx]), ylabel=ylab, levels=nlev, title="e_tot", color=:haline)
p2 = contourf(x, z, transpose(data_a["e_pot"][:, y_idx, :, time_idx]),              levels=nlev, title="e_pot", color=:haline)
p3 = contourf(x, z, transpose(data_a["e_kin"][:, y_idx, :, time_idx]), ylabel=ylab, levels=nlev, title="e_kin", color=:haline)
p4 = contourf(x, z, transpose(data_a["e_int"][:, y_idx, :, time_idx]),              levels=nlev, title="e_int", color=:haline)
p5 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["rain_w"][:, y_idx, :, time_idx]) != max.(data_a["rain_w"][:, y_idx, :, time_idx])
    p5 = contourf(x, z, transpose(data_s["rain_w"][:, y_idx, :, time_idx]), ylabel=ylab, xlabel=xlab, levels=nlev, title="rain_w [m/s]", color=:haline)
end
p6 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["snow_w"][:, y_idx, :, time_idx]) != max.(data_a["snow_w"][:, y_idx, :, time_idx])
    p6 = contourf(x, z, transpose(data_a["snow_w"][:, y_idx, :, time_idx]), xlabel=xlab, levels=nlev, title="snow_w [m/s]", color=:haline)
end
fig = plot(p1, p2, p3, p4, p5, p6, layout=(3, 2), size=(1500, 1000))
savefig(fig, string(analysis_folder, "quicklook_energy_and_velocity.pdf"))

# microphysics variables
p1 = contourf(x, z, transpose(data_a["q_tot"][:, y_idx, :, time_idx])*1e3, ylabel=ylab, levels=nlev, title="q_tot [g/kg]", color=:haline)
p2 = contourf(x, z, transpose(data_a["q_vap"][:, y_idx, :, time_idx])*1e3,              levels=nlev, title="q_vap [g/kg]", color=:haline)
p3 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["q_liq"][:, y_idx, :, time_idx]) != max.(data_a["q_liq"][:, y_idx, :, time_idx])
    p3 = contourf(x, z, transpose(data_a["q_liq"][:, y_idx, :, time_idx])*1e3, ylabel=ylab, levels=nlev, title="q_liq [g/kg]", color=:haline)
end
p4 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["q_ice"][:, y_idx, :, time_idx]) != max.(data_a["q_ice"][:, y_idx, :, time_idx])
    p4 = contourf(x, z, transpose(data_a["q_ice"][:, y_idx, :, time_idx])*1e3, levels=nlev, title="q_ice [g/kg]", color=:haline)
end
p5 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["q_rai"][:, y_idx, :, time_idx]) != max.(data_a["q_rai"][:, y_idx, :, time_idx])
    p5 = contourf(x, z, transpose(data_a["q_rai"][:, y_idx, :, time_idx])*1e3, ylabel=ylab, xlabel=xlab, levels=nlev, title="q_rai [g/kg]", color=:haline)
end
p6 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["q_sno"][:, y_idx, :, time_idx]) != max.(data_a["q_sno"][:, y_idx, :, time_idx])
    p6 = contourf(x, z, transpose(data_a["q_sno"][:, y_idx, :, time_idx])*1e3, xlabel=xlab, levels=nlev, title="q_sno [g/kg]", color=:haline)
end
fig = plot(p1, p2, p3, p4, p5, p6, layout=(3, 2), size=(1500, 1000))
savefig(fig, string(analysis_folder, "quicklook_microph.pdf"))

# flags and supersaturations
p1 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["S_liq"][:, y_idx, :, time_idx]) != max.(data_a["S_liq"][:, y_idx, :, time_idx])
    p1 = contourf(x, z, transpose(data_a["S_liq"][:, y_idx, :, time_idx])*1e3, ylabel=ylab, levels=nlev, title="S_liq [-]", color=:haline)
end
p2 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["S_ice"][:, y_idx, :, time_idx]) != max.(data_a["S_ice"][:, y_idx, :, time_idx])
    p2 = contourf(x, z, transpose(data_a["S_ice"][:, y_idx, :, time_idx])*1e3, levels=nlev, title="S_ice [-]", color=:haline)
end
p3 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["flag_cloud_liq"][:, y_idx, :, time_idx]) != max.(data_a["flag_cloud_liq"][:, y_idx, :, time_idx])
    p3 = contourf(x, z, transpose(data_a["flag_cloud_liq"][:, y_idx, :, time_idx])*1e3, ylabel=ylab, levels=nlev, title="flag cloud liq", color=:haline)
end
p4 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["flag_cloud_ice"][:, y_idx, :, time_idx]) != max.(data_a["flag_cloud_ice"][:, y_idx, :, time_idx])
    p4 = contourf(x, z, transpose(data_a["flag_cloud_ice"][:, y_idx, :, time_idx])*1e3, levels=nlev, title="flag cloud ice", color=:haline)
end
p5 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["flag_rain"][:, y_idx, :, time_idx]) != max.(data_a["flag_rain"][:, y_idx, :, time_idx])
    p5 = contourf(x, z, transpose(data_a["flag_rain"][:, y_idx, :, time_idx])*1e3, ylabel=ylab, xlabel=xlab, levels=nlev, title="flag rain", color=:haline)
end
p6 = plot(legend=false,grid=false,foreground_color_subplot=:white)
if min.(data_a["flag_snow"][:, y_idx, :, time_idx]) != max.(data_a["flag_snow"][:, y_idx, :, time_idx])
    p6 = contourf(x, z, transpose(data_a["flag_snow"][:, y_idx, :, time_idx])*1e3, xlabel=xlab, levels=nlev, title="flag snow", color=:haline)
end
fig = plot(p1, p2, p3, p4, p5, p6, layout=(3, 2), size=(1500, 1000))
savefig(fig, string(analysis_folder, "quicklook_flag_and_sat.pdf"))

