using VizCLIMA, Documenter

pages = Any[
    "Home" => "index.md",
    "VizCLIMA Scripts" => "vizclima_script_examples.md",
    "End-to-end Modeling (SLURM)" => "slurm_users_end_to_end.md",
    "Nimbus" => "datavis.md",
    "Gallery" => "gallery.md",
    "Third party software" => "third_party.md"
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
