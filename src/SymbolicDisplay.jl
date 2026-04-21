"""
    symbolic_transform(x; simplify=:auto, expand=false, factor=false, collect=nothing)

Apply optional symbolic transformations for display. Works with Symbolics and SymPy.
Non-symbolic inputs are returned unchanged.
"""
function symbolic_transform(x; simplify=:auto, expand=false, factor=false, collect=nothing)
    if x isa Symbolics.Num
        y = x
        if expand
            y = try
                Symbolics.Num(Symbolics.SymbolicUtils.expand(Symbolics.unwrap(y)))
            catch
                y
            end
        end
        if factor
            y = try
                isdefined(Symbolics, :factor) ? Symbolics.factor(y) : y
            catch
                y
            end
        end
        if simplify === true
            y = try
                Symbolics.simplify(y)
            catch
                y
            end
        end
        if collect !== nothing
            y = try
                Symbolics.collect(y, collect)
            catch
                y
            end
        end
        return y
    end

    if Symbolics.SymbolicUtils.issym(x) || Symbolics.SymbolicUtils.iscall(x)
        return symbolic_transform(Symbolics.Num(x); simplify=simplify, expand=expand, factor=factor, collect=collect)
    end

    if _is_pythoncall_py(x)
        sympy = import_sympy()
        y = x
        if simplify !== false
            y = sympy.simplify(y)
        end
        if expand
            y = sympy.expand(y)
        end
        if factor
            y = sympy.factor(y)
        end
        if collect !== nothing
            y = sympy.collect(y, collect)
        end
        return y
    end

    return x
end

"""
    normalize_symopts(symopts) -> NamedTuple

Normalize symbolic display options to a `NamedTuple` for safe keyword splatting.
"""
function normalize_symopts(symopts)
    if symopts === nothing
        return NamedTuple()
    end
    if symopts isa NamedTuple
        return symopts
    end
    if symopts isa Dict
        return (; symopts...)
    end
    if symopts isa Pair
        return (; symopts)
    end
    if symopts isa Bool
        throw(ArgumentError("symopts must be a NamedTuple; use symopts=(; factor=true)"))
    end
    throw(ArgumentError("symopts must be a NamedTuple, Dict, or Pair"))
end

"""
    symbolic_term_coefficients(expr) -> Vector{Any}

Return the numeric multipliers for each additive term in a Symbolics expression.

Examples:
- `symbolic_term_coefficients((1//2) * x + 2x * y)` returns `[1//2, 2]`
- `symbolic_term_coefficients(1 + 3x)` returns `[1, 3]`
"""
function _symbolics_unwrap_num(expr)
    return expr isa Symbolics.Num ? Symbolics.unwrap(expr) : expr
end

function _symbolics_storage(expr)
    expr = _symbolics_unwrap_num(expr)
    return hasfield(typeof(expr), :data) ? getfield(expr, :data) : expr
end

function _symbolics_storage_dict(storage)
    return hasfield(typeof(storage), :dict) ? getfield(storage, :dict) : nothing
end

function _symbolics_storage_coeff(storage)
    return hasfield(typeof(storage), :coeff) ? getfield(storage, :coeff) : nothing
end

function _symbolics_coefficients_from_storage(storage)
    coeffs = Any[]
    const_coeff = _symbolics_storage_coeff(storage)
    if const_coeff !== nothing && !iszero(const_coeff)
        push!(coeffs, const_coeff)
    end
    dict = _symbolics_storage_dict(storage)
    if dict !== nothing
        append!(coeffs, values(dict))
    end
    return coeffs
end

function symbolic_term_coefficients(expr)
    expr = _symbolics_unwrap_num(expr)
    storage = _symbolics_storage(expr)
    dict = _symbolics_storage_dict(storage)
    coeff = _symbolics_storage_coeff(storage)

    # SymbolicUtils stores Add/Mul numeric coefficients separately from symbolic
    # term keys. Keep that internal storage knowledge isolated here.
    if Symbolics.SymbolicUtils.isadd(expr) && dict !== nothing
        return _symbolics_coefficients_from_storage(storage)
    end

    if Symbolics.SymbolicUtils.ismul(expr) && coeff !== nothing
        return Any[coeff]
    end

    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) == (+)
        coeffs = Any[]
        for arg in Symbolics.SymbolicUtils.arguments(expr)
            append!(coeffs, symbolic_term_coefficients(arg))
        end
        return coeffs
    end

    return Any[1]
end
