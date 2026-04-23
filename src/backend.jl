"""
Use eithe Symbolics.jl (default) or SymPy
"""
module Backend

export BackendTag, SymbolicsBackend, SymPyBackend, get_backend, set_backend!, backend_available

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
    backend_available(::Type{SymbolicsBackend}) -> Bool

Return true when the Symbolics backend is available.
"""
backend_available(::Type{SymbolicsBackend}) = true

"""
    backend_available(::Type{SymPyBackend}) -> Bool

Return true when SymPy appears available in the current PythonCall runtime.

This probes the configured Python environment without importing and caching the
`sympy` module itself. Use `import_sympy()` for explicit initialization and
diagnostics.
"""
function backend_available(::Type{SymPyBackend})
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
