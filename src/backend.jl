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

Return true when the SymPy backend is available.
"""
function backend_available(::Type{SymPyBackend})
    parent = parentmodule(@__MODULE__)
    if !isdefined(parent, :import_sympy)
        return false
    end
    try
        Base.invokelatest(getfield(parent, :import_sympy))
        return true
    catch
        return false
    end
end

end # module
