using BlockArrays
using LaTeXStrings
using Latexify
using LinearAlgebra
using PythonCall
using Symbolics

"""
    is_none_val(x) -> Bool

Return true when `x` is treated as a sentinel for "no value".
"""
is_none_val(x) = x === :none || x === nothing

"""
    fix_num_symbol_mul(s::AbstractString) -> String

Remove `\\cdot` only in numeric-times-symbol patterns for cleaner LaTeX output.
"""
fix_num_symbol_mul(s::AbstractString) = replace(String(s),
    r"(?:(?<=^)|(?<=\s))(-?(?:\d+(?:\.\d+)?))\s*\\cdot\s+(?=(\\?[A-Za-z]))" => s"\1 ",
    r"(\\frac\{[^}]+\}\{[^}]+\})\s*\\cdot\s+(?=(\\?[A-Za-z]))"               => s"\1 ",
    r"(\\left\([^)]*\\right\))\s*\\cdot\s+(?=(\\?[A-Za-z]))"                 => s"\1 ",
)

"""
    to_latex(x; number_formatter=nothing) -> String

Convert a Julia object to a LaTeX string, with optional number formatting.
"""
function to_latex(x::LaTeXString; number_formatter=nothing)
    return strip(string(x), ['$', '\n'])
end

function to_latex(x::String; number_formatter=nothing)
    stripped = strip(x)
    if startswith(stripped, "\\") ||
       all(c -> isdigit(c) || c in (' ', '=', '+', '-', '*', '/', '(', ')', '^', '.', ','), stripped)
        return stripped
    end
    sanitized_str = replace(x, "_" => "\\_", "\$" => "\\\$")
    return "\\text{" * sanitized_str * "}"
end

function to_latex(x::Char; number_formatter=nothing)
    return to_latex(string(x))
end

function to_latex(x::Rational{Int}; number_formatter=nothing)
    n, d = numerator(x), denominator(x)
    if d == 1
        return string(n)
    else
        sign_str = n < 0 ? "-" : ""
        return sign_str * "\\frac{$(abs(n))}{$d}"
    end
end

function to_latex(x::Complex{T}; number_formatter=nothing) where T
    x_real = real(x)
    x_imag = imag(x)

    if x_imag == 0
        return to_latex(x_real, number_formatter=number_formatter)
    elseif x_real == 0
        if x_imag == 1
            return "\\mathit{i}"
        elseif x_imag == -1
            return "-\\mathit{i}"
        else
            return to_latex(x_imag, number_formatter=number_formatter) * "\\mathit{i}"
        end
    else
        xr = to_latex(x_real; number_formatter=number_formatter)
        sgn = x_imag < 0 ? "-" : "+"
        axi = abs(x_imag)
        xi = (axi == 1 ? "" : to_latex(axi; number_formatter=number_formatter)) * "\\mathit{i}"
        return xr * sgn * xi
    end
end

function to_latex(x::Float64; number_formatter=nothing)
    x = number_formatter !== nothing ? number_formatter(x) : x
    str_x = string(x)
    if occursin('e', str_x)
        base, exponent = split(str_x, 'e')
        exponent = replace(exponent, "+" => "")
        return base * " e^{" * exponent * "}"
    else
        return str_x
    end
end

function to_latex(x::Symbol; number_formatter=nothing)
    return string(x)
end

function to_latex(x::Symbolics.Num; number_formatter=nothing)
    s = strip(string(latexify(Symbolics.simplify(x))), ['$', '\n', ' '])
    s = replace(s, r"^\\begin\{equation\}\s*" => "", r"\s*\\end\{equation\}\s*$" => "")
    s = replace(s, r"\\mathtt\{([^}]*)\}" => s"\1")
    s = replace(s, "\\_" => "_")
    return isempty(s) ? string(x) : s
end

function to_latex(x; number_formatter=nothing)
    if x isa PythonCall.Py
        sympy = import_sympy()
        s = strip(PythonCall.pyconvert(String, sympy.latex(x)), ['$', '\n'])
        s = fix_num_symbol_mul(s)
        s = replace(
            s,
            raw"\mathrm{I}" => raw"\mathit{i}",
            r"(?<![A-Za-z\\])I(?![A-Za-z])" => raw"\mathit{i}",
            r"(?<=^|\s)1\s*(\\mathit\{i\})" => (m -> m.captures[1]),
        )
        return s
    end

    s = strip(latexify(x), ['$', '\n'])
    return isempty(s) ? string(x) : s
end

function to_latex(A::AbstractArray; number_formatter=nothing)
    return map(x -> to_latex(x; number_formatter=number_formatter), A)
end

function to_latex(A::Transpose; number_formatter=nothing)
    return to_latex(parent(A); number_formatter=number_formatter)'
end

function to_latex(A::Adjoint; number_formatter=nothing)
    return to_latex(parent(A); number_formatter=number_formatter)'
end

function to_latex(A::BlockArray; number_formatter=nothing)
    return to_latex(Matrix(A); number_formatter=number_formatter)
end

function to_latex(matrices::Vector; number_formatter=nothing)
    return [[is_none_val(mat) ? nothing : to_latex(mat; number_formatter=number_formatter) for mat in row] for row in matrices]
end
