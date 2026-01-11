"""
Use eithe Symbolics.jl (default) or SymPy
"""
module Backend

export BackendTag, SymbolicsBackend, SymPyBackend, get_backend, set_backend!, backend_available

abstract type BackendTag end
struct SymbolicsBackend <: BackendTag end
struct SymPyBackend      <: BackendTag end

const _backend = Ref{BackendTag}(SymbolicsBackend())

get_backend() = _backend[]
set_backend!(b::BackendTag) = (_backend[] = b)

# availability hooks (Symbolics always available)
backend_available(::Type{SymbolicsBackend}) = true
backend_available(::Type{SymPyBackend}) = false  # flipped to true in the extension

end # module

