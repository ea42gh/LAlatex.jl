module LAlatex
using PythonCall
using Symbolics

include("backend.jl")
include("symbolics_backend.jl")
include("import_sympy.jl")

using .Backend
using .SymbolicsBackendImpl: syms_symbolics

export @syms, syms, syms_sympy, @syms_sympy, import_sympy, get_backend, set_backend!

"""
    get_backend() -> BackendTag

Return the currently selected backend tag.
"""
get_backend() = Backend.get_backend()

"""
    set_backend!(backend)

Set the default backend for this session. Supported tags:
- `Backend.SymbolicsBackend()`
- `Backend.SymPyBackend()`
"""
set_backend!(b::Backend.BackendTag) = Backend.set_backend!(b)

"""
    syms(names...; backend=:default, kwargs...)

Create symbols using either Symbolics (default) or SymPy.

`syms` exists primarily to provide a Symbolics-friendly constructor; use `backend=:sympy`
or `syms_sympy` when you want SymPy symbols instead.

- `backend=:symbolics` returns Symbolics variables (`Symbolics.Num`)
- `backend=:sympy` returns SymPy symbols via PythonCall (`PythonCall.Py`)

Notes:
- Symbolics does not accept SymPy-style assumption keywords (e.g., `real=true`); this function errors
  if you pass keyword arguments with the Symbolics backend.
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
