using BlockArrays
using LaTeXStrings
using Latexify
using LinearAlgebra
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

function _to_latex_symbolics(x::Symbolics.Num; number_formatter=nothing)
    y = x
    s = _symbolics_to_latex(y)
    s = normalize_symbolics_latex(s)
    return isempty(s) ? string(y) : s
end

function _symbolics_to_latex(x::Symbolics.Num)
    return _symbolics_to_latex(Symbolics.unwrap(x))
end

function _symbolics_to_latex(x::Integer)
    return string(x)
end

function _symbolics_to_latex(x::Rational)
    n, d = numerator(x), denominator(x)
    if d == 1
        return string(n)
    end
    sign_str = n < 0 ? "-" : ""
    return sign_str * "\\frac{$(abs(n))}{$d}"
end

function _symbolics_to_latex(x::AbstractFloat)
    return to_latex(x)
end

function _symbolics_to_latex(x::Irrational{:π})
    return "\\pi"
end

function _symbolics_to_latex(x::Symbol)
    return string(x)
end

function _symbolic_function_latex_name(op)
    op === log && return "\\log"
    op === sin && return "\\sin"
    op === cos && return "\\cos"
    op === tan && return "\\tan"
    op === asin && return "\\arcsin"
    op === acos && return "\\arccos"
    op === atan && return "\\arctan"
    op === sinh && return "\\sinh"
    op === cosh && return "\\cosh"
    op === tanh && return "\\tanh"
    op === asinh && return "\\operatorname{asinh}"
    op === acosh && return "\\operatorname{acosh}"
    op === atanh && return "\\operatorname{atanh}"
    return nothing
end

function _symbolics_to_latex(x)
    sx = string(x)
    if sx == "π"
        return "\\pi"
    end

    if Symbolics.SymbolicUtils.issym(x)
        return sx == "π" ? "\\pi" : sx
    end

    if Symbolics.SymbolicUtils.is_literal_number(x)
        return _symbolics_to_latex(Symbolics.SymbolicUtils.unwrap_const(x))
    end

    if Symbolics.SymbolicUtils.iscall(x)
        op = Symbolics.SymbolicUtils.operation(x)
        args = Symbolics.SymbolicUtils.arguments(x)

        if op === (/)
            return "\\frac{$(_symbolics_to_latex(args[1]))}{$(_symbolics_to_latex(args[2]))}"
        elseif op === (*)
            pieces = String[]
            sign_prefix = ""
            for arg in args
                if Symbolics.SymbolicUtils.is_literal_number(arg)
                    val = Symbolics.SymbolicUtils.unwrap_const(arg)
                    if length(args) > 1 && val == 1
                        continue
                    elseif length(args) > 1 && val == -1
                        sign_prefix = "-"
                        continue
                    end
                end
                part = _symbolics_to_latex(arg)
                if Symbolics.SymbolicUtils.iscall(arg)
                    argop = Symbolics.SymbolicUtils.operation(arg)
                    if argop === (+) || argop === (-)
                        part = "\\left(" * part * "\\right)"
                    end
                end
                push!(pieces, part)
            end
            body = join(pieces, " ")
            isempty(body) && return sign_prefix == "-" ? "-1" : "1"
            return sign_prefix * body
        elseif op === (+)
            out = _symbolics_to_latex(args[1])
            for arg in Iterators.drop(args, 1)
                part = _symbolics_to_latex(arg)
                if startswith(part, "-")
                    out *= " - " * strip(part[2:end])
                else
                    out *= " + " * part
                end
            end
            return out
        elseif op === (-)
            if length(args) == 1
                return "-" * _symbolics_to_latex(args[1])
            end
            return _symbolics_to_latex(args[1]) * " - " * _symbolics_to_latex(args[2])
        elseif op === (^)
            base = _symbolics_to_latex(args[1])
            expo = _symbolics_to_latex(args[2])
            if Symbolics.SymbolicUtils.iscall(args[1]) || startswith(base, "\\frac")
                base = "\\left(" * base * "\\right)"
            end
            return base * "^{" * expo * "}"
        elseif op === sqrt
            return "\\sqrt{$(_symbolics_to_latex(args[1]))}"
        elseif op === exp
            return "e^{" * _symbolics_to_latex(args[1]) * "}"
        else
            latex_name = _symbolic_function_latex_name(op)
            if latex_name !== nothing && length(args) == 1
                return latex_name * "\\left(" * _symbolics_to_latex(args[1]) * "\\right)"
            end
        end
    end

    s = string(latexify(x))
    return isempty(s) ? string(x) : s
end

function _to_latex_sympy(x)
    pc = _ensure_pythoncall()
    sympy = import_sympy()
    s = strip(pc.pyconvert(String, sympy.latex(x)), ['$', '\n'])
    s = fix_num_symbol_mul(s)
    s = replace(
        s,
        raw"\mathrm{I}" => raw"\mathit{i}",
        r"(?<![A-Za-z\\])I(?![A-Za-z])" => raw"\mathit{i}",
        r"(?<=^|\s)1\s*(\\mathit\{i\})" => (m -> m.captures[1]),
    )
    return s
end

function _to_latex_scalar(x; number_formatter=nothing)
    if _is_pythoncall_py(x)
        return _to_latex_sympy(x)
    elseif x isa Symbolics.Num
        return _to_latex_symbolics(x; number_formatter=number_formatter)
    elseif x isa Complex
        return _to_latex_complex(x; number_formatter=number_formatter)
    end

    formatted_x = number_formatter !== nothing && x isa Number ? number_formatter(x) : x
    s = strip_math_delims(latexify(formatted_x))
    return isempty(s) ? string(formatted_x) : s
end

function _to_latex_matrix_entry(x; number_formatter=nothing)
    return _to_latex_scalar(x; number_formatter=number_formatter)
end

"""
    to_latex(x; number_formatter=nothing) -> String

Convert a Julia object to a LaTeX string, with optional number formatting.
"""
function to_latex(x; number_formatter=nothing)
    return _to_latex_scalar(x; number_formatter=number_formatter)
end

"""
    to_latex(x::LaTeXString; number_formatter=nothing) -> String
"""
function to_latex(x::LaTeXString; number_formatter=nothing)
    return strip_math_delims(string(x))
end

"""
    to_latex(x::String; number_formatter=nothing) -> String

Convert a string to LaTeX, treating math-like strings as math.
"""
function to_latex(x::String; number_formatter=nothing)
    if looks_like_math(x)
        return strip_math_delims(x)
    end
    sanitized = sanitize_text(x)
    return "\\text{" * sanitized * "}"
end

"""
    to_latex(x::Char; number_formatter=nothing) -> String
"""
function to_latex(x::Char; number_formatter=nothing)
    return to_latex(string(x))
end

"""
    to_latex(x::Rational{Int}; number_formatter=nothing) -> String
"""
function to_latex(x::Rational{Int}; number_formatter=nothing)
    n, d = numerator(x), denominator(x)
    if d == 1
        return string(n)
    else
        sign_str = n < 0 ? "-" : ""
        return sign_str * "\\frac{$(abs(n))}{$d}"
    end
end

"""
    to_latex(x::Complex; number_formatter=nothing) -> String
"""
function _to_latex_complex(x::Complex; number_formatter=nothing)
    x_real = real(x)
    x_imag = imag(x)
    real_numeric = x_real isa Number && !(x_real isa Symbolics.Num)
    imag_numeric = x_imag isa Number && !(x_imag isa Symbolics.Num)

    if imag_numeric && x_imag == 0
        return _to_latex_scalar(x_real, number_formatter=number_formatter)
    elseif real_numeric && x_real == 0
        if imag_numeric && x_imag == 1
            return "\\mathit{i}"
        elseif imag_numeric && x_imag == -1
            return "-\\mathit{i}"
        else
            return _to_latex_scalar(x_imag, number_formatter=number_formatter) * "\\mathit{i}"
        end
    else
        xr = _to_latex_scalar(x_real; number_formatter=number_formatter)
        sgn = "+"
        coeff = ""
        if imag_numeric
            sgn = x_imag < 0 ? "-" : "+"
            axi = abs(x_imag)
            coeff = (axi == 1 ? "" : _to_latex_scalar(axi; number_formatter=number_formatter))
        else
            imag_str = strip(_to_latex_scalar(x_imag; number_formatter=number_formatter))
            if startswith(imag_str, "-")
                sgn = "-"
                imag_str = strip(imag_str[2:end])
            end
            coeff = imag_str == "1" ? "" : imag_str
        end
        xi = coeff * "\\mathit{i}"
        return xr * sgn * xi
    end
end

function to_latex(x::Complex{T}; number_formatter=nothing) where T
    return _to_latex_complex(x; number_formatter=number_formatter)
end

"""
    to_latex(x::Float64; number_formatter=nothing) -> String
"""
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

"""
    to_latex(x::Symbol; number_formatter=nothing) -> String
"""
function to_latex(x::Symbol; number_formatter=nothing)
    return string(x)
end

"""
    to_latex(x::Symbolics.Num; number_formatter=nothing) -> String
"""
function to_latex(x::Symbolics.Num; number_formatter=nothing)
    return _to_latex_scalar(x; number_formatter=number_formatter)
end

"""
    to_latex(A::AbstractArray; number_formatter=nothing)
"""
function to_latex(A::AbstractArray; number_formatter=nothing)
    return map(x -> _to_latex_matrix_entry(x; number_formatter=number_formatter), A)
end

"""
    to_latex(A::Transpose; number_formatter=nothing)
"""
function to_latex(A::Transpose; number_formatter=nothing)
    return permutedims(to_latex(parent(A); number_formatter=number_formatter))
end

"""
    to_latex(A::Adjoint; number_formatter=nothing)
"""
function to_latex(A::Adjoint; number_formatter=nothing)
    return permutedims(to_latex(parent(A); number_formatter=number_formatter))
end

"""
    to_latex(A::BlockArray; number_formatter=nothing)
"""
function to_latex(A::BlockArray; number_formatter=nothing)
    return map(x -> _to_latex_matrix_entry(x; number_formatter=number_formatter), Array(A))
end

"""
    to_latex(matrices::AbstractVector{<:AbstractVector}; number_formatter=nothing)
"""
function to_latex(matrices::AbstractVector{<:AbstractVector}; number_formatter=nothing)
    return [[is_none_val(mat) ? nothing : to_latex(mat; number_formatter=number_formatter) for mat in row] for row in matrices]
end
