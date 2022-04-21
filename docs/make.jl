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
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/BatyLeo/ConstrainedShortestPaths.jl",
    devbranch="main",
)
