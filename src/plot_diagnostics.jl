"""
    plot_diagnostics.jl

Plotting tools for output of CLIMA results.
"""

using Pkg
Pkg.add("https://github.com/climate-machine/CLIMA")
using CLIMA

using Plots; pyplot()
using DataFrames
using FileIO
using DelimitedFiles
import PyPlot

"""
    start(args::Vector{String}, out_plot_dir::AbstractString, diagnostic_vars::F) where {F<:Function}

Usage:
    `julia plot_diagnostics.jl <diagnostic_file.jld2> <diagnostic_name>`
"""
function start(args::Vector{String},
               out_plot_dir::AbstractString,
               diagnostic_vars::F,
               zvertical) where {F<:Function}
    #data = load(args[1])

    # USER INPUTS:
    user_specified_timestart = 0
    user_specified_timeend   = -12329.963523831071 # set it to -1 to only plot the last time step
    time_average = "y"
    isimex = "y"
    dh=40
    dv=20

    # List the directories containing the JLD2 files to post-process:
    gcloud_VM = ["yt-DYCOMS-MULTI-RATE-NEW-MOIST-THERMO"] #EDDY

    for gcloud in gcloud_VM


        SGS = "Smago"

        ode_str = "imex"

        file = joinpath(clima_path, "output","EDDY", gcloud, "IMPL", "diagnostics-2020-01-16T22:11:26.296.jld2")
        data = load(file) #Dsub=0 component-wise Geostrophic forcing
        file = joinpath(clima_path, "output","EDDY", gcloud, "IMPL", "diagnostics-2020-01-17T07:44:12.648.jld2")
        data = load(file) # D=-3.7



    info_str = string(dh,"X", dv, "-SGS-", ode_str)

    out_vars = ["ht_sgs",
                "qt_sgs",
                "h_m",
                "h_t",
                "vert_eddy_qt_flx",
                "q_tot",
                "q_liq",
                "wvariance",
                "wskew",
                "thd",
                "thv",
                "thl",
                "w",
                "uvariance",
                "vvariance",
                "vert_eddy_thv_flx",
                "u",
                "v"]

    # END USER INPUTS:

    # Stevens et al. 2005 measurements:
    dir = joinpath(clima_path, "output", "Stevens2005Data")
    qt_stevens  = readdlm(joinpath(dir, "experimental_qt_stevens2005.csv"), ',', Float64)
    ql_stevens  = readdlm(joinpath(dir, "experimental_ql_stevens2005.csv"), ',', Float64)
    thl_stevens = readdlm(joinpath(dir, "experimental_thetal_stevens2005.csv"), ',', Float64)
    tkelower_stevens = readdlm(joinpath(dir, "lower_limit_tke_time_stevens2005.csv"), ',', Float64)
    tkeupper_stevens = readdlm(joinpath(dir, "upper_limit_tke_time_stevens2005.csv"), ',', Float64)


    @show keys(data)
    println("data for $(length(data)) time steps in file")

    diff = 100

    times = parse.(Float64,keys(data))

    if user_specified_timestart < 0
        timestart = minimum(times)
        @show(timestart)
    else
        timestart = user_specified_timestart
        @show(timestart)
    end
    if user_specified_timeend < 0
        timeend = maximum(times)
        @show(timeend)
    else
        timeend = user_specified_timeend
        @show(timeend)
    end

    time_data = string(timeend)
    Nqk = size(data[time_data], 1)
    nvertelem = size(data[time_data], 2)
    Z = zeros(Nqk * nvertelem)
    for ev in 1:nvertelem
        for k in 1:Nqk
            dv = diagnostic_vars(data[time_data][k,ev])
            Z[k+(ev-1)*Nqk] = dv.z
        end
    end

    n_vars = length(out_vars)
    V  = zeros(Nqk * nvertelem, n_vars)

    if time_average == "yes" || time_average == "y"
        time_average_str = "Tave"
        timestr = string(info_str, ". ", SGS, time_average_str, ".", ceil(timeend), " s")
        key = time_data #this is a string
        ntimes = 0
        for key in keys(data)
            if  parse.(Float64,key) > timestart
                for ev in 1:nvertelem
                    for k in 1:Nqk
                        dv = diagnostic_vars(data[key][k,ev])
                        i = k+(ev-1)*Nqk
                        for j in 1:n_vars
                          V[i, j] += getproperty(dv, Symbol(out_vars[j]))
                        end
                    end
                end
                ntimes += 1
            end #end if timestart
        end
    else
        time_average_str = "Tinst"
        key = time_data #this is a string
        timestr = string(info_str, ". ", SGS, ". At t= ", ceil(timeend), " s")
        ntimes = 1
        for ev in 1:nvertelem
            for k in 1:Nqk
                dv = diagnostic_vars(data[key][k,ev])
                i = k+(ev-1)*Nqk
                for j in 1:n_vars
                  V[i, j] += getproperty(dv, Symbol(out_vars[j]))
                end
            end
        end
    end
    @show "Total times steps " ntimes

    p1 = plot(V[:,1]/ntimes, Z,
              linewidth=3,
              xaxis=("ht_sgs", (0, 250), 0:25:250),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("ht_sgs"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    p2 = plot(V[:,2]/ntimes, Z,
              linewidth=3,
              xaxis=("qt_sgs", (-5e-5, 2e-5)),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("qt_sgs"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    labels = ["h_m = e_i + gz + RmT" "h_t = e_t + RmT"]
    p3 = plot([V[:,3]/ntimes V[:,4]/ntimes], Z,
              linewidth=3,
              xaxis=("Moist and total enthalpies"), #(1.08e8, 1.28e8), 1.08e8:0.1e8:1.28e8),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=labels,
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    pwqt = plot(V[:,5]*1e+3/ntimes, Z,
              linewidth=3,
              xaxis=("<w' qt'> (m/s g/kg)"), #(0, 0.), 0:0.:1),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<w qt>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    pqt = plot(V[:,6]*1e+3/ntimes, Z,
              linewidth=3,
              xaxis=("<qt>", (0, 12), 0:2:12),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<qt>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    qt_rf01 = qt_stevens[:,1]
    z_rf01  = qt_stevens[:,2]
    p5 = plot!(qt_rf01,z_rf01,seriestype=:scatter,
               markersize = 10,
               markercolor = :black,
               label=("<qt experimental>")
               )
##

    pql = plot(V[:,7]*1e+3/ntimes, Z,
              linewidth=3,
              xaxis=("<ql>"), #(-0.05, 0.5), -0.05:0.1:0.5),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<ql>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black], label="")

    ql_rf01 = ql_stevens[:,1]
    z_rf01  = ql_stevens[:,2]
    p6 = plot!(ql_rf01,z_rf01,seriestype=:scatter,
               markersize = 10,
               markercolor = :black,
               label=("<ql experimental>")
               )

    puu = plot(V[:,14]/ntimes, Z,
              linewidth=3,
              xaxis=("<u'u'>"),# (-0.1, 0.6), -0.1:0.1:0.6),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<u'u'>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    pvv = plot(V[:,15]/ntimes, Z,
              linewidth=3,
              xaxis=("<v'v'>"),# (-0.1, 0.6), -0.1:0.1:0.6),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<v'v'>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")


    pww = plot(V[:,8]/ntimes, Z,
              linewidth=3,
              xaxis=("<w'w'>"),# (-0.1, 0.6), -0.1:0.1:0.6),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<w'w'>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

   tke = 0.5*(V[:,14].*V[:,14] + V[:,15].*V[:,15] + V[:,8].*V[:,8])
   ptke = plot(tke/ntimes^2, Z,
              linewidth=3,
              xaxis=("TKE"),# (-0.1, 0.6), -0.1:0.1:0.6),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<TKE>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    tke_rf01 = tkelower_stevens[:,1]
    z_rf01   = tkelower_stevens[:,2]
   # ptke = plot!(tke_rf01,z_rf01,seriestype=:scatter,
   #            markersize = 10,
   #            markercolor = :black,
   #            label=("<lower limit tke experimental>"))


    pwww = plot(V[:,9]/ntimes, Z,
              linewidth=3,
              xaxis=("<w'w'w'>"), #, (-0.15, 0.15), -0.15:0.05:0.15),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<w'w'w'>"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    data = [V[:,10]/ntimes V[:,11]/ntimes V[:,12]/ntimes]
    labels = ["θ" "θv" "θl"]
    pthl = plot(data, Z,
              linewidth=3,
              xaxis=("<θ>", (285, 310), 285:5:310),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=labels,
               )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    thl_rf01 = thl_stevens[:,1]
    z_rf01  = thl_stevens[:,2]
    pthl = plot!(thl_rf01, z_rf01, seriestype=:scatter,
               markersize = 10,
               markercolor = :black,
              label=("<thl experimental>"))

    pth = plot(data, Z,
              linewidth=3,
              xaxis=("<θ>", (285, 310), 285:5:310),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=labels,
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")
##

    B = 9.81*V[:,16]/290.4
    pB = plot(B/ntimes, Z,
              linewidth=3,
              xaxis=("g<w'θv>/θ_0"), #, (-0.15, 0.15), -0.15:0.05:0.15),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("g<w'θv>/θ_0"),
               )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

  #=  vert_eddy_thl_flx = plot(V21/ntimes, Z,
              linewidth=3,
              xaxis=("<w'θ_l'>"), #, (-0.15, 0.15), -0.15:0.05:0.15),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("<w'θ_l'>"),
               )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")
=#
    pu = plot(V[:,17]/ntimes, Z,
              linewidth=3,
              xaxis=("u", (0, 10), 0:2:10),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("u (m/s)"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    pv = plot(V[:,18]/ntimes, Z,
              linewidth=3,
              xaxis=("v", (-10, 0), -10:2:0),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("v (m/s)"),
              )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")

    pw = plot(V[:,13]/ntimes, Z,
              linewidth=3,
              xaxis=("w"), #, (-0.15, 0.15), -0.15:0.05:0.15),
              yaxis=("Altitude[m]", (0, zvertical)),
              label=("w (m/s)"),
               )
    hline!( [600, 840], width=[1,1], linestyle=[:dash, :dash], color=[:black],  label="")


    f=font(14,"courier")
    all_plots = plot(pu,  pv,  pw,   pthl,
                     pqt, pql, pwqt, pB,
                     puu, pww, pwww, ptke,
                     layout = (3,4), titlefont=f, tickfont=f, legendfont=f, guidefont=f) #, title=timestr)

    plot!(size=(2200,1200))
    outfile_name = string(info_str,"-", ode_str,"-", time_average_str, "-from-", timestart,"-to-", ceil(timeend),"s.png")
    f = joinpath(out_plot_dir, "plots", outfile_name)
    savefig(all_plots, f)

   #= one_plot = plot(vert_eddy_thl_flx, titlefont=f, tickfont=f, legendfont=f, guidefont=f, title=timestr)
    outfile_name = string("eddy_THETAL_flx.", info_str,".", ode_str,".", time_average_str, ".t", ceil(timeend),"s.png")
    plot!(size=(2200,1000))
    savefig(one_plot, joinpath(string(out_plot_dir,"/plots/"), outfile_name))
=#
end
end

#if length(ARGS) != 3 || !endswith(ARGS[1], ".jld2")
#    usage()
#end
start(ARGS,
      "output",
      CLIMA.Diagnostics.diagnostic_vars,
      dirname(pathof(CLIMA)),
      1500)
