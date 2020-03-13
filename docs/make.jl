using VizCLIMA, Documenter

pages = Any[
  "Home" => "index.md"
]

makedocs(
  sitename = "VizCLIMA.jl",
  doctest = false,
  strict = false,
  format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true",
        mathengine = MathJax(Dict(
            :TeX => Dict(
                :equationNumbers => Dict(:autoNumber => "AMS"),
                :Macros => Dict()
            )
        ))
  ),
  clean = false,
  modules = [Documenter, VizCLIMA],
  pages = pages,
)

deploydocs(
           repo = "github.com/climate-machine/VizCLIMA.jl.git",
           target = "build",
          )
