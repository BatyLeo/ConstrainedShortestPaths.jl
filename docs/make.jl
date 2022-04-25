using ConstrainedShortestPaths
using Documenter

DocMeta.setdocmeta!(ConstrainedShortestPaths, :DocTestSetup, :(using ConstrainedShortestPaths); recursive=true)

makedocs(;
    modules=[ConstrainedShortestPaths],
    authors="BatyLeo and contributors",
    repo="https://github.com/BatyLeo/ConstrainedShortestPaths.jl/blob/{commit}{path}#{line}",
    sitename="ConstrainedShortestPaths.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://BatyLeo.github.io/ConstrainedShortestPaths.jl",
        assets=String[],
        # collapselevel = 1,
    ),
    pages=[
        "Home" => "index.md",
        "Mathematical background" => ["math.md", "examples.md"],
        "Tutorials" => ["tutorial.md", "custom.md"],
        "api.md",
    ],
)

deploydocs(;
    repo="github.com/BatyLeo/ConstrainedShortestPaths.jl",
    devbranch="main",
)
