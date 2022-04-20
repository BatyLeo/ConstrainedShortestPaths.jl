using RCSP
using Documenter

DocMeta.setdocmeta!(RCSP, :DocTestSetup, :(using RCSP); recursive=true)

makedocs(;
    modules=[RCSP],
    authors="BatyLeo <leo.baty67@gmail.com> and contributors",
    repo="https://github.com/BatyLeo/RCSP.jl/blob/{commit}{path}#{line}",
    sitename="RCSP.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://BatyLeo.github.io/RCSP.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/BatyLeo/RCSP.jl",
    devbranch="main",
)
