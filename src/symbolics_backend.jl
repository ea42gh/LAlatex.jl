module SymbolicsBackendImpl

using Symbolics
using ..Backend: SymbolicsBackend

export syms_symbolics, assume_symbolics!, symbolics_assumptions

const _symbolics_assumptions = IdDict{Any, Dict{Symbol, Any}}()

"""
    assume_symbolics!(var; kwargs...) -> var

Attach assumption metadata to a Symbolics variable for downstream display/formatting.
"""
function assume_symbolics!(var; kwargs...)
    isempty(kwargs) && return var
    store = get!(_symbolics_assumptions, var) do
        Dict{Symbol, Any}()
    end
    for (k, v) in kwargs
        store[k] = v
    end
    return var
end

"""
    symbolics_assumptions(var) -> Dict{Symbol,Any}

Return a copy of the stored Symbolics assumptions for `var`.
"""
function symbolics_assumptions(var)
    return copy(get(_symbolics_assumptions, var, Dict{Symbol, Any}()))
end

"""
    syms_symbolics(names...; kwargs...)

Create one or more Symbolics variables.

Assumption keywords are recorded as metadata for later use in display or formatting.
"""
function syms_symbolics(names::Union{Symbol,String}...; kwargs...)
    vars = [Symbolics.variable(n isa Symbol ? String(n) : n) for n in names]
    for v in vars
        assume_symbolics!(v; kwargs...)
    end
    return length(vars) == 1 ? first(vars) : Tuple(vars)
end

end # module
