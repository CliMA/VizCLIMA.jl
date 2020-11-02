using VizCLIMA, Documenter

pages = Any[
  "Home" => "index.md"
]

makedocs(
  sitename = "VizCLIMA.jl",
  doctest = false,
  strict = true,
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
  modules = [VizCLIMA],
  pages = pages,
)

deploydocs(
    repo = "github.com/CliMA/VizCLIMA.jl.git",
    target = "build",
    push_preview = true,
    forcepush = true,
)
