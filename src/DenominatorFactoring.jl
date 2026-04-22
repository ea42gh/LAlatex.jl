using BlockArrays: BlockArray
using LinearAlgebra: Adjoint, Transpose

"""
    factor_out_denominator(A) -> (factor, A_factored)

Return a common denominator factor and a scaled array for rational inputs.
"""
function factor_out_denominator(A)
    return 1, A
end

function _symbolics_unwrap_literal(val)
    if val isa Symbolics.Num
        val = Symbolics.unwrap(val)
    end
    if Symbolics.SymbolicUtils.is_literal_number(val)
        return Symbolics.SymbolicUtils.unwrap_const(val)
    end
    return val
end

function _push_literal_denominator!(denominators::Vector{<:Integer}, val; include_integers=false)
    val = _symbolics_unwrap_literal(val)
    if val isa Rational
        push!(denominators, denominator(val))
    elseif include_integers && val isa Integer
        push!(denominators, abs(val))
    elseif val isa Complex && real(val) isa Rational && imag(val) isa Rational
        push!(denominators, denominator(real(val)))
        push!(denominators, denominator(imag(val)))
    end
    return denominators
end

function _push_divisor_denominator!(denominators::Vector{<:Integer}, val)
    val = _symbolics_unwrap_literal(val)
    if val isa Integer
        push!(denominators, abs(val))
    elseif val isa Rational
        n = numerator(val)
        !iszero(n) && push!(denominators, abs(n))
    end
    return denominators
end

function _collect_symbolics_division_key_denominators!(denominators::Vector{<:Integer}, expr)
    expr = _symbolics_unwrap_num(expr)
    if Symbolics.SymbolicUtils.iscall(expr) && Symbolics.SymbolicUtils.operation(expr) === (/)
        args = Symbolics.SymbolicUtils.arguments(expr)
        length(args) >= 2 && _push_divisor_denominator!(denominators, args[2])
        _collect_symbolics_denominators!(denominators, args[1])
    end
    return denominators
end

function _collect_symbolics_denominators!(denominators::Vector{<:Integer}, expr; include_integers=false)
    expr = _symbolics_unwrap_num(expr)

    if Symbolics.SymbolicUtils.is_literal_number(expr)
        return _push_literal_denominator!(denominators, expr; include_integers=include_integers)
    end

    if expr isa Rational
        push!(denominators, denominator(expr))
        return denominators
    elseif include_integers && expr isa Integer
        push!(denominators, abs(expr))
        return denominators
    elseif expr isa Complex && real(expr) isa Rational && imag(expr) isa Rational
        push!(denominators, denominator(real(expr)))
        push!(denominators, denominator(imag(expr)))
        return denominators
    elseif expr isa Number
        return denominators
    end

    storage = _symbolics_storage(expr)
    dict = _symbolics_storage_dict(storage)
    if dict !== nothing
        if Symbolics.SymbolicUtils.isadd(expr)
            coeff = _symbolics_storage_coeff(storage)
            if coeff !== nothing
                _push_literal_denominator!(denominators, coeff)
            end
            for (term, coeff) in dict
                _push_literal_denominator!(denominators, coeff)
                _collect_symbolics_division_key_denominators!(denominators, term)
            end
            return denominators
        elseif Symbolics.SymbolicUtils.ismul(expr)
            coeff = _symbolics_storage_coeff(storage)
            if coeff !== nothing
                _push_literal_denominator!(denominators, coeff)
            end
            return denominators
        end
    end

    if Symbolics.SymbolicUtils.iscall(expr)
        op = Symbolics.SymbolicUtils.operation(expr)
        args = Symbolics.SymbolicUtils.arguments(expr)
        if op === (/) && length(args) >= 2
            _collect_symbolics_denominators!(denominators, args[1])
            _push_divisor_denominator!(denominators, args[2])
            return denominators
        elseif op === (+)
            for arg in args
                _collect_symbolics_denominators!(denominators, arg; include_integers=include_integers)
            end
            return denominators
        elseif op === (*)
            ok, rat = Symbolics.SymbolicUtils.ratcoeff(expr)
            if ok
                _push_literal_denominator!(denominators, rat; include_integers=include_integers)
            else
                for arg in args
                    if _symbolics_unwrap_literal(arg) isa Number
                        _push_literal_denominator!(denominators, arg; include_integers=include_integers)
                    elseif Symbolics.SymbolicUtils.iscall(arg) && Symbolics.SymbolicUtils.operation(arg) === (/)
                        _collect_symbolics_division_key_denominators!(denominators, arg)
                    end
                end
            end
            return denominators
        end
    end
    return denominators
end

function _symbolics_denominators(expr; include_integers=false)
    denominators = Integer[]
    _collect_symbolics_denominators!(denominators, expr; include_integers=include_integers)
    return denominators
end

function _push_sympy_denominator!(denominators::Vector{<:Integer}, x)
    _is_pythoncall_py(x) || return denominators
    den = try
        sympy = import_sympy()
        sympy.denom(sympy.together(x))
    catch
        nothing
    end
    den === nothing && return denominators

    pc = _ensure_pythoncall()
    pc === nothing && return denominators
    den_jl = try
        pc.pyconvert(Any, den)
    catch
        nothing
    end
    if den_jl isa Integer
        push!(denominators, den_jl)
    elseif den_jl isa Rational
        push!(denominators, denominator(den_jl))
    end
    return denominators
end

function _scaled_rational_integer(d, x::Rational)
    return numerator(d * x)
end

function _scaled_complex_rational_integer(d, x::Complex)
    return complex(_scaled_rational_integer(d, real(x)), _scaled_rational_integer(d, imag(x)))
end

function _contains_symbolics(x)
    if x isa Symbolics.Num || Symbolics.SymbolicUtils.issym(x) || Symbolics.SymbolicUtils.iscall(x)
        return true
    elseif x isa Complex
        return _contains_symbolics(real(x)) || _contains_symbolics(imag(x))
    end
    return false
end

"""
    factor_out_denominator(A::AbstractArray) -> (factor, A_factored)

Factor out the least common denominator for rational entries in mixed arrays.
Symbols and non-rational numeric entries are scaled by the factor; unsupported
entries return the original array with factor 1.

For symbolic entries, denominator factoring is intentionally coefficient-level:
literal rational entries, numeric symbolic coefficients, and explicit scalar
divisions such as `x / 2` contribute denominators. Denominators buried inside
symbolic factors, powers, or functions, such as `(3//10)^n`, do not. Non-scalar
symbolic denominators such as `x / (2y)` also do not contribute a display-wide
factor.
"""
function factor_out_denominator(A::AbstractArray)
    denominators = Integer[]
    for x in A
        if x isa Rational
            push!(denominators, denominator(x))
        elseif x isa Complex && real(x) isa Rational && imag(x) isa Rational
            push!(denominators, denominator(real(x)))
            push!(denominators, denominator(imag(x)))
        elseif x isa Complex
            xr = real(x)
            xi = imag(x)
            if xr isa Symbolics.Num
                _collect_symbolics_denominators!(denominators, xr)
            elseif _is_pythoncall_py(xr)
                _push_sympy_denominator!(denominators, xr)
            end
            if xi isa Symbolics.Num
                _collect_symbolics_denominators!(denominators, xi)
            elseif _is_pythoncall_py(xi)
                _push_sympy_denominator!(denominators, xi)
            end
        elseif x isa Symbolics.Num
            _collect_symbolics_denominators!(denominators, x)
        elseif _is_pythoncall_py(x)
            _push_sympy_denominator!(denominators, x)
        elseif x isa Number || x isa Symbolics.Num
            # ok
        else
            return 1, A
        end
    end

    if isempty(denominators)
        return 1, A
    end

    d = reduce(lcm, denominators; init=1)
    d == 1 && return 1, A
    factored = map(x -> d * x, A)
    if any(_contains_symbolics, factored)
        factored = try
            Symbolics.expand.(factored)
        catch
            factored
        end
    elseif any(_is_pythoncall_py, factored)
        sympy = import_sympy()
        factored = map(x -> _is_pythoncall_py(x) ? sympy.expand(x) : x, factored)
    end
    return d, factored
end

"""
    factor_out_denominator(A::AbstractVector{<:Rational}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a rational vector.
"""
function factor_out_denominator(A::AbstractVector{<:Rational})
    isempty(A) && return 1, A
    d = reduce(lcm, denominator.(A); init=1)
    return d, map(x -> _scaled_rational_integer(d, x), A)
end

"""
    factor_out_denominator(A::AbstractMatrix{<:Rational}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a rational matrix.
"""
function factor_out_denominator(A::AbstractMatrix{<:Rational})
    isempty(A) && return 1, A
    d = reduce(lcm, denominator.(A); init=1)
    return d, map(x -> _scaled_rational_integer(d, x), A)
end

"""
    factor_out_denominator(A::AbstractVector{<:Complex{<:Rational}}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a complex rational vector.
"""
function factor_out_denominator(A::AbstractVector{<:Complex{<:Rational}})
    denominators_real = denominator.(real.(A))
    denominators_imag = denominator.(imag.(A))
    d = reduce(lcm, vcat(denominators_real, denominators_imag), init=1)
    return d, map(x -> _scaled_complex_rational_integer(d, x), A)
end

"""
    factor_out_denominator(A::AbstractMatrix{<:Complex{<:Rational}}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a complex rational matrix.
"""
function factor_out_denominator(A::AbstractMatrix{<:Complex{<:Rational}})
    denominators_real = denominator.(real.(A))
    denominators_imag = denominator.(imag.(A))
    d = reduce(lcm, vcat(denominators_real, denominators_imag), init=1)
    return d, map(x -> _scaled_complex_rational_integer(d, x), A)
end

"""
    factor_out_denominator(A::Transpose) -> (factor, A_factored)

Preserve transposition while factoring denominators.
"""
function factor_out_denominator(A::Transpose)
    d, A_factored = factor_out_denominator(parent(A))
    return d, transpose(A_factored)
end

"""
    factor_out_denominator(A::BlockArray) -> (factor, A_factored)

Factor denominators in a BlockArray and reconstruct the block structure.
"""
function factor_out_denominator(A::BlockArray)
    dense_array = copy(Array(A))
    d, A_factored = factor_out_denominator(dense_array)
    return d, BlockArray(A_factored, axes(A))
end

"""
    factor_out_denominator(A::Adjoint) -> (factor, A_factored)

Preserve adjoint while factoring denominators.
"""
function factor_out_denominator(A::Adjoint)
    d, A_factored = factor_out_denominator(parent(A))
    return d, A_factored'
end

"""
    factor_out_denominator(A::Base.ReshapedArray) -> (factor, A_factored)

Factor denominators while preserving the original reshaped size.
"""
function factor_out_denominator(A::Base.ReshapedArray{T, 2, Adjoint{T, Vector{T}}, Tuple{}}) where T
    original_shape = size(A)
    d, A_factored = factor_out_denominator(parent(A))
    reshaped_A_factored = reshape(A_factored, original_shape)
    return d, reshaped_A_factored
end
