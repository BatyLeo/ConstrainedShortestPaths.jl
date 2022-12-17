using ConstrainedShortestPaths
using Documenter
using Literate

DocMeta.setdocmeta!(
    ConstrainedShortestPaths,
    :DocTestSetup,
    :(using ConstrainedShortestPaths);
    recursive=true
)

# Copy README.md into docs/src/index.md (overwriting)

open(joinpath(@__DIR__, "src", "index.md"), "w") do io
    println(
        io,
        """
        ```@meta
        EditURL = "https://github.com/BatyLeo/ConstrainedShortestPaths.jl/blob/main/README.md"
        ```
        """,
    )
    # Write the contents out below the meta bloc
    for line in eachline(joinpath(dirname(@__DIR__), "README.md"))
        println(io, line)
    end
end

# Tutorials with literates

md_dir = joinpath(@__DIR__, "src")
jl_dir = joinpath(md_dir, "literate")

utils_file = joinpath(md_dir, "utils.jl")
Literate.markdown(utils_file, md_dir; documenter=true, execute=false)

# last element if for custom, others are for tutorial
tuto_list = [
    "basic_shortest_path",
    "resource_shortest_path",
    "stochastic_vsp",
    "custom",
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
        "maths.md",
        "Tutorial" => ["$tuto.md" for tuto in tuto_list],
        #"$(tuto_list[end]).md",
        "api.md",
    ],
)

deploydocs(;
    repo="github.com/BatyLeo/ConstrainedShortestPaths.jl",
    devbranch="main",
)
