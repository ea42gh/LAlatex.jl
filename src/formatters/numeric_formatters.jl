"""
    scientific_formatter(x; digits=2) -> String

Format a numeric value in scientific notation using the base-10 exponent.
"""
function _scientific_parts(x; digits=2)
    if iszero(x)
        return round(float(x); digits=digits), 0
    end

    exponent = floor(Int, log10(abs(x)))
    mantissa = round(x / 10.0^exponent; digits=digits)
    if abs(mantissa) >= 10
        mantissa /= 10
        exponent += 1
    end
    return mantissa, exponent
end

function scientific_formatter(x; digits=2)
    mantissa, exponent = _scientific_parts(x; digits=digits)
    return string(mantissa, "e", exponent)
end

"""
    percentage_formatter(x; digits=2) -> Real

Format a numeric value as a percentage (without appending a percent sign).
"""
function percentage_formatter(x; digits=2)
    return round(x * 100, digits=digits)
end

"""
    exponential_formatter(x; digits=2) -> Union{String,Real}

Format values outside [1e-3, 1e3) using compact exponential notation.
"""
function exponential_formatter(x; digits=2)
    if iszero(x)
        return x isa Integer ? x : round(x; digits=digits)
    elseif abs(x) >= 1e3 || abs(x) < 1e-3
        return scientific_formatter(x; digits=digits)
    else
        return x isa Integer ? x : round(x; digits=digits)
    end
end
