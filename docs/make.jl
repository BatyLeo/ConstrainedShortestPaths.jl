using ConstrainedShortestPaths
using Documenter
using Literate

DocMeta.setdocmeta!(
    ConstrainedShortestPaths,
    :DocTestSetup,
    :(using ConstrainedShortestPaths);
    recursive=true
)

md_dir = joinpath(@__DIR__, "src")
jl_dir = joinpath(md_dir, "literate")

# last element if for custom, others are for tutorial
tuto_list = [
    "basic_shortest_path",
    "resource_shortest_path",
    "stochastic_vsp",
    "custom"
]

for tuto in tuto_list
    jl_file = joinpath(jl_dir, "$tuto.jl")
    Literate.markdown(jl_file, md_dir; documenter=true, execute=false)
end

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
        "Tutorial" => ["$tuto.md" for tuto in tuto_list[1:end-1]],
        "Mathematical background" => ["setting.md", "algorithms.md", "examples.md"],
        "$(tuto_list[end]).md",
        "api.md",
    ],
)

deploydocs(;
    repo="github.com/BatyLeo/ConstrainedShortestPaths.jl",
    devbranch="main",
)
