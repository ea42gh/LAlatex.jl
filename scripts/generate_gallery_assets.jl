using LAlatex
using LaTeXStrings
using Symbolics

function require_tool(name)
    path = Sys.which(name)
    path === nothing && error("Required tool not found on PATH: $name")
    return path
end

latex = require_tool("latex")
dvisvgm = require_tool("dvisvgm")

outdir = normpath(joinpath(@__DIR__, "..", "assets"))
mkpath(outdir)

set_backend!(:symbolics)
LAlatex.@syms x

assets = Dict(
    "set_display" => l_show(
        "S = ",
        set([1, 0, 0], [0, 1, 0], [0, 0, 1];
            arraystyle = :parray,
            separator = L",\;"),
    ),
    "cases_display" => l_show(
        "f(x) = ",
        cases(
            x^2 => L"x \ge 0",
            (-x, L"x < 0"),
        ),
    ),
    "aligned_display" => l_show(
        aligned(
            (L"(\xi)", L"\Leftrightarrow", L"Ax = b"),
            ("", L"\Rightarrow", L"A^T A x = A^T b"),
        ),
    ),
)

for (name, latex_body) in assets
    mktempdir() do tmp
        texfile = joinpath(tmp, "$(name).tex")
        open(texfile, "w") do io
            write(io, """
\\documentclass[preview]{standalone}
\\usepackage{amsmath,amssymb}
\\begin{document}
$(String(latex_body))
\\end{document}
""")
        end

        run(`$latex -interaction=nonstopmode -halt-on-error -output-directory=$tmp $texfile`)
        dvi = joinpath(tmp, "$(name).dvi")
        svg = joinpath(outdir, "$(name).svg")
        run(`$dvisvgm --no-fonts --exact-bbox -o $svg $dvi`)
    end
end
