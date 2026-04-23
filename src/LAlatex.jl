module LAlatex

const _pythoncall_loaded = Ref(false)

_in_precompile() = ccall(:jl_generating_output, Cint, ()) == 1
_pythoncall_disabled() = get(ENV, "LALATEX_DISABLE_PYTHONCALL", "") != ""

function _pythoncall_module()
    return isdefined(@__MODULE__, :PythonCall) ? Base.invokelatest(getfield, @__MODULE__, :PythonCall) : nothing
end

function _ensure_pythoncall()
    if _pythoncall_disabled()
        return nothing
    end
    if _in_precompile()
        return nothing
    end
    if !_pythoncall_loaded[]
        try
            @eval import PythonCall
        catch err
            if Base.find_package("PythonCall") === nothing
                error(
                    "PythonCall is not installed in the active environment.\n\n" *
                    "Install optional SymPy support with:\n" *
                    "  using Pkg; Pkg.add(\"PythonCall\")\n\n" *
                    "Original error:\n$err"
                )
            end
            rethrow()
        end
        _pythoncall_loaded[] = true
    end
    return Base.invokelatest(getfield, @__MODULE__, :PythonCall)
end

function _is_pythoncall_py(x)
    pc = _pythoncall_module()
    return pc !== nothing && x isa pc.Py
end

function _sympy_module_name(x)
    pc = _pythoncall_module()
    if pc === nothing || !(x isa pc.Py)
        return nothing
    end
    try
        cls = Base.invokelatest(pc.pygetattr, x, "__class__")
        mod = Base.invokelatest(pc.pygetattr, cls, "__module__")
        return String(Base.invokelatest(pc.pyconvert, String, mod))
    catch
        return nothing
    end
end

function _is_sympy_py(x)
    mod = _sympy_module_name(x)
    return mod !== nothing && (mod == "sympy" || startswith(mod, "sympy."))
end
using Symbolics
using PrecompileTools

include("backend.jl")
include("symbolics_backend.jl")
include("import_sympy.jl")
include("FormattingUtils.jl")
include("Formatters.jl")
include("MatrixUtils.jl")
include("SymbolicDisplay.jl")
include("DenominatorFactoring.jl")

using .Backend
using .SymbolicsBackendImpl: syms_symbolics, assume_symbolics!, symbolics_assumptions

export get_backend, set_backend!
export @syms, syms, syms_sympy, @syms_sympy, import_sympy, assume!, assumptions
export symbolic_transform, symbolic_term_coefficients

export to_latex, L_show, l_show, L_interp
export to_html, show_html, pr, capture_output, show_side_by_side_html, show_side_by_side

export mixed_matrix, @mixed_matrix, set, lc, cases, aligned
export apply_function, round_value, round_matrices, print_np_array_def, factor_out_denominator

export bold_formatter, italic_formatter, color_formatter, conditional_color_formatter
export highlight_large_values, underline_formatter, overline_formatter, combine_formatters
export scientific_formatter, percentage_formatter, exponential_formatter
export tril_formatter, block_formatter, diagonal_blocks_formatter, jordanblock_formatter, rowechelon_formatter

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
"""
    set_backend!(backend::Symbol)

Set the default backend using `:symbolics` or `:sympy`.
"""
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

@setup_workload begin
    int_matrix = [1 2 3; 4 5 6]
    rational_matrix = [1//2 1//3; 2//3 3//4]
    int_vector = [1, 2, 3]
    x, y = syms(:x, :y)
    symbolic_matrix = mixed_matrix((1//2, x), (3, y))
    identity_cols = [1 0; 0 1]

    @compile_workload begin
        to_latex(3)
        to_latex(3//4)
        to_latex(1.2e3)
        to_latex(int_vector)
        to_latex(int_matrix)

        L_show(LaTeXString("A = "), int_matrix, LaTeXString(",\\quad A^T A = "), int_matrix' * int_matrix)
        l_show(LaTeXString("A = "), int_matrix, LaTeXString(",\\quad A^T A = "), int_matrix' * int_matrix)
        L_show(LaTeXString("R = "), rational_matrix)
        L_show(LaTeXString("v = "), int_vector)
        L_show(LaTeXString("M = "), symbolic_matrix; symopts=(expand=true,))
        L_show(lc([1, -2], identity_cols))
        L_show(cases(int_vector => LaTeXString("x > 0"), rational_matrix => "otherwise"))
        L_show(aligned(LaTeXString("A") => int_matrix, (LaTeXString("x"), LaTeXString("\\in"), int_vector)))

        to_html("warmup"; sz=12)
        show_side_by_side_html(["left"], ["right"])
    end
end
# ===============================================================
end
