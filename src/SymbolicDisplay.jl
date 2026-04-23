"""
    symbolic_transform(x; simplify=:auto, expand=false, factor=false, collect=nothing)

Apply optional symbolic transformations for display. Works with Symbolics and SymPy.
Non-symbolic inputs are returned unchanged.
"""
function symbolic_transform(x; simplify=:auto, expand=false, factor=false, collect=nothing)
    if x isa Complex
        return symbolic_transform(real(x); simplify=simplify, expand=expand, factor=factor, collect=collect) +
               im * symbolic_transform(imag(x); simplify=simplify, expand=expand, factor=factor, collect=collect)
    end

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

function _contains_symbolic_value(x)
    if x isa Complex
        return _contains_symbolic_value(real(x)) || _contains_symbolic_value(imag(x))
    end
    return x isa Symbolics.Num ||
           _is_pythoncall_py(x) ||
           Symbolics.SymbolicUtils.issym(x) ||
           Symbolics.SymbolicUtils.iscall(x)
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

function symbolic_term_coefficients(expr)
    expr = _symbolics_unwrap_num(expr)

    if Symbolics.SymbolicUtils.is_literal_number(expr)
        return Any[Symbolics.SymbolicUtils.unwrap_const(expr)]
    end

    if expr isa Number
        return Any[expr]
    end

    if Symbolics.SymbolicUtils.ismul(expr)
        coeff = try
            Symbolics.SymbolicUtils.get_mul_coefficient(expr)
        catch
            nothing
        end
        coeff !== nothing && return Any[coeff]
    end

    # Prefer the public TermInterface argument view over direct storage access.
    if Symbolics.SymbolicUtils.isadd(expr)
        coeffs = Any[]
        for arg in Symbolics.SymbolicUtils.arguments(expr)
            append!(coeffs, symbolic_term_coefficients(arg))
        end
        return coeffs
    end

    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) == (+)
        coeffs = Any[]
        for arg in Symbolics.SymbolicUtils.arguments(expr)
            append!(coeffs, symbolic_term_coefficients(arg))
        end
        return coeffs
    end

    if Symbolics.SymbolicUtils.ismul(expr)
        coeff = try
            Symbolics.SymbolicUtils.get_mul_coefficient(expr)
        catch
            nothing
        end
        coeff !== nothing && return Any[coeff]
    end

    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) == (*)
        coeff = try
            Symbolics.SymbolicUtils.get_mul_coefficient(expr)
        catch
            nothing
        end
        coeff !== nothing && return Any[coeff]
    end

    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) == (-) &&
       length(Symbolics.SymbolicUtils.arguments(expr)) == 1
        coeffs = symbolic_term_coefficients(Symbolics.SymbolicUtils.arguments(expr)[1])
        return map(-, coeffs)
    end

    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) == (-) &&
       length(Symbolics.SymbolicUtils.arguments(expr)) == 2
        coeffs = symbolic_term_coefficients(Symbolics.SymbolicUtils.arguments(expr)[1])
        append!(coeffs, map(-, symbolic_term_coefficients(Symbolics.SymbolicUtils.arguments(expr)[2])))
        return coeffs
    end

    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) == (/) &&
       length(Symbolics.SymbolicUtils.arguments(expr)) >= 1
        return symbolic_term_coefficients(Symbolics.SymbolicUtils.arguments(expr)[1])
    end

    return Any[1]
end
