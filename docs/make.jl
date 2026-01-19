using LAlatex
using Documenter

DocMeta.setdocmeta!(LAlatex, :DocTestSetup, :(using LAlatex); recursive=true)

makedocs(;
    modules=[LAlatex],
    authors="ea42_github@mail.com",
    sitename="LAlatex.jl",
    format=Documenter.HTML(;
        canonical="https://ea42gh.github.io/LAlatex.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Quickstart" => "quickstart.md",
        "Python interop" => "python-interop.md",
        "Compatibility" => "compatibility.md",
        "FAQ" => "faq.md",
        "Examples" => "examples.md",
        "API" => "api.md",
    ],
)

deploydocs(;
    repo="github.com/ea42gh/LAlatex.jl",
    devbranch="main",
)
