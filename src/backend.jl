"""
Use eithe Symbolics.jl (default) or SymPy
"""
module Backend

export BackendTag, SymbolicsBackend, SymPyBackend, get_backend, set_backend!, backend_usable

abstract type BackendTag end
struct SymbolicsBackend <: BackendTag end
struct SymPyBackend      <: BackendTag end

const _backend = Ref{BackendTag}(SymbolicsBackend())

"""
    get_backend() -> BackendTag

Return the currently selected backend tag.
"""
get_backend() = _backend[]

"""
    set_backend!(backend::BackendTag)

Set the default backend for the current session.
"""
set_backend!(b::BackendTag) = (_backend[] = b)

# availability hooks (Symbolics always available)
"""
    backend_usable(::Type{SymbolicsBackend}) -> Bool

Return true when the Symbolics backend is available.
"""
backend_usable(::Type{SymbolicsBackend}) = true

"""
    backend_usable(::Type{SymPyBackend}) -> Bool

Return true when SymPy can be imported in the current PythonCall runtime.

This may initialize Python and import `sympy`, but it does not cache the module
inside `LAlatex`. Use `import_sympy()` for explicit initialization and
diagnostics.
"""
function backend_usable(::Type{SymPyBackend})
    parent = parentmodule(@__MODULE__)
    if !isdefined(parent, :_sympy_probe)
        return false
    end
    try
        return Base.invokelatest(getfield(parent, :_sympy_probe))
    catch
        return false
    end
end

end # module
