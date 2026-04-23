using Pkg

Pkg.develop(path=joinpath(@__DIR__, ".."))
Pkg.resolve()
Pkg.instantiate()

using LAlatex
using Documenter

DocMeta.setdocmeta!(LAlatex, :DocTestSetup, :(using LAlatex); recursive=true)

makedocs(;
    modules=[LAlatex],
    checkdocs=:exports,
    authors="ea42_github@mail.com",
    sitename="LAlatex.jl",
    format=Documenter.HTML(;
        canonical="https://ea42gh.github.io/LAlatex",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Installation" => "installation.md",
        "Quickstart" => "quickstart.md",
        "Python interop" => "python-interop.md",
        "Display policy" => "display-policy.md",
        "Compatibility" => "compatibility.md",
        "FAQ" => "faq.md",
        "Examples" => "examples.md",
        "API" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/ea42gh/LAlatex",
    devbranch="main",
)
