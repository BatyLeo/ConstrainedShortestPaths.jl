using ConstrainedShortestPaths
using Documenter
using Literate

DocMeta.setdocmeta!(ConstrainedShortestPaths, :DocTestSetup, :(using ConstrainedShortestPaths); recursive=true)

wrapper_jl_file = joinpath(dirname(@__DIR__), "test", "tutorial.jl")
custom_jl_file = joinpath(dirname(@__DIR__), "test", "custom.jl")
tuto_md_dir = joinpath(@__DIR__, "src")
Literate.markdown(wrapper_jl_file, tuto_md_dir; documenter=true, execute=false)
Literate.markdown(custom_jl_file, tuto_md_dir; documenter=true, execute=false)

makedocs(;
    modules=[ConstrainedShortestPaths],
    authors="BatyLeo and contributors",
    repo="https://github.com/BatyLeo/ConstrainedShortestPaths.jl/blob/{commit}{path}#{line}",
    sitename="ConstrainedShortestPaths.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://BatyLeo.github.io/ConstrainedShortestPaths.jl",
        assets=String[],
        collapselevel = 1,
    ),
    pages=[
        "Home" => "index.md",
        "tutorial.md",
        "Mathematical background" => ["math.md", "examples.md"],
        "custom.md",
        "api.md",
    ],
)

deploydocs(;
    repo="github.com/BatyLeo/ConstrainedShortestPaths.jl",
    devbranch="main",
)
