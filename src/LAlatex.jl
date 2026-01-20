module LAlatex
using PythonCall
using Symbolics

include("backend.jl")
include("symbolics_backend.jl")
include("import_sympy.jl")
include("FormattingUtils.jl")
include("Formatters.jl")
include("MatrixUtils.jl")
include("SymbolicDisplay.jl")

using .Backend
using .SymbolicsBackendImpl: syms_symbolics, assume_symbolics!, symbolics_assumptions

export @syms, syms, syms_sympy, @syms_sympy, import_sympy, get_backend, set_backend!, assume!, assumptions
export to_html, show_html, pr, capture_output, show_side_by_side_html, show_side_by_side
export bold_formatter, italic_formatter, color_formatter, conditional_color_formatter
export highlight_large_values, underline_formatter, overline_formatter, combine_formatters
export scientific_formatter, percentage_formatter, exponential_formatter
export tril_formatter, block_formatter, diagonal_blocks_formatter, rowechelon_formatter
export to_latex
export mixed_matrix, @mixed_matrix
export L_show, l_show, set, lc
export L_interp, apply_function, round_value, round_matrices, print_np_array_def, factor_out_denominator
export symbolic_transform
export symbolic_term_coefficients
export factor_out_denominator

"""
    Base.transpose(x::Char)

Return `x` unchanged for display helpers.
"""
Base.transpose(x::Char) = x

"""
    Base.adjoint(x::Char)

Return `x` unchanged for display helpers.
"""
Base.adjoint(x::Char) = x

"""
    Base.transpose(x::String)

Return `x` unchanged for display helpers.
"""
Base.transpose(x::String) = x

"""
    Base.adjoint(x::String)

Return `x` unchanged for display helpers.
"""
Base.adjoint(x::String) = x

"""
    Base.transpose(x::LaTeXString)

Return `x` unchanged for display helpers.
"""
Base.transpose(x::LaTeXString) = x

"""
    Base.adjoint(x::LaTeXString)

Return `x` unchanged for display helpers.
"""
Base.adjoint(x::LaTeXString) = x

"""
    get_backend() -> BackendTag

Return the currently selected backend tag.
"""
get_backend() = Backend.get_backend()

"""
    set_backend!(backend)

Set the default backend for this session. Supported values:
- `Backend.SymbolicsBackend()` or `:symbolics`
- `Backend.SymPyBackend()` or `:sympy`
"""
set_backend!(b::Backend.BackendTag) = Backend.set_backend!(b)
function set_backend!(backend::Symbol)
    if backend === :symbolics
        return set_backend!(Backend.SymbolicsBackend())
    elseif backend === :sympy
        return set_backend!(Backend.SymPyBackend())
    else
        throw(ArgumentError("Unknown backend: $backend (expected :symbolics or :sympy)"))
    end
end

"""
    assume!(var; kwargs...) -> var

Attach assumptions to a Symbolics variable. Assumptions are stored as metadata for LAlatex.
"""
function assume!(var; kwargs...)
    if var isa Symbolics.Num
        return assume_symbolics!(var; kwargs...)
    end
    throw(ArgumentError("assume! expects a Symbolics variable; use SymPy assumptions with SymPy backend."))
end

"""
    assumptions(var) -> Dict{Symbol,Any}

Return stored assumptions for a Symbolics variable, or an empty dict if none are recorded.
"""
function assumptions(var)
    if var isa Symbolics.Num
        return symbolics_assumptions(var)
    end
    return Dict{Symbol, Any}()
end

"""
    syms(names...; backend=:default, kwargs...)

Create symbols using either Symbolics (default) or SymPy.

`syms` exists primarily to provide a Symbolics-friendly constructor; use `backend=:sympy`
or `syms_sympy` when you want SymPy symbols instead.

- `backend=:symbolics` returns Symbolics variables (`Symbolics.Num`)
- `backend=:sympy` returns SymPy symbols via PythonCall (`PythonCall.Py`)

Notes:
- Symbolics assumptions passed as keywords are stored as metadata for LAlatex formatting and display.
"""
function syms(names...; backend::Symbol = :default, kwargs...)
    if backend === :default
        backend = get_backend() isa Backend.SymPyBackend ? :sympy : :symbolics
    end
    if backend === :symbolics
        return syms_symbolics(names...; kwargs...)
    elseif backend === :sympy
        return syms_sympy(names...; kwargs...)
    else
        throw(ArgumentError("Unknown backend: $backend (expected :symbolics or :sympy)"))
    end
end

"""
    @syms x y z [(:key => value)...]

Bind symbols to Julia variables using the active backend.
"""
macro syms(args...)
    vars = Symbol[]
    opts = Expr[]  # store `Expr(:kw, key, val)` later

    for a in args
        if a isa Symbol
            push!(vars, a)
        elseif a isa Expr && a.head == :call && a.args[1] == :(=>) && length(a.args) == 3
            key = a.args[2]
            val = a.args[3]
            if key isa QuoteNode
                key = key.value
            end
            key isa Symbol || throw(ArgumentError("@syms option keys must be Symbols; got: $(key)"))
            push!(opts, Expr(:kw, key, val))
        else
            throw(ArgumentError("@syms expects Symbols and optional `key => value` pairs; got: $(a)"))
        end
    end

    assigns = Expr[]
    for v in vars
        name_str = String(v)
        if isempty(opts)
            push!(assigns, :( $(esc(v)) = LAlatex.syms($name_str) ))
        else
            kw = Expr(:parameters, opts...)
            push!(assigns, :( $(esc(v)) = LAlatex.syms($kw, $name_str) ))
        end
    end

    return Expr(:block, assigns...)
end

# ===============================================================
include("Convert.jl")
include("HTMLDisplay.jl")
include("LatexRepresentations.jl")
include("L_show.jl")
# ===============================================================
end
