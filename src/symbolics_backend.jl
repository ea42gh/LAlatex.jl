module SymbolicsBackendImpl

using Symbolics
using ..Backend: SymbolicsBackend

export syms_symbolics

function syms_symbolics(names::Union{Symbol,String}...; kwargs...)
    # Symbolics doesn't accept SymPy-style assumptions keywords directly.
    # So for now: ignore or error on kwargs (your choice).
    if !isempty(kwargs)
        throw(ArgumentError("Symbolics backend does not support SymPy-style assumptions keywords: $(keys(kwargs))."))
    end
    vars = Symbolics.variables(map(n -> n isa Symbol ? String(n) : n, names)...)
    return length(vars) == 1 ? first(vars) : Tuple(vars)
end

end # module

