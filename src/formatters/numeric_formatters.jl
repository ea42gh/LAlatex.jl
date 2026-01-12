"""
    scientific_formatter(x; digits=2) -> String

Format a numeric value in scientific notation using the base-10 exponent.
"""
function scientific_formatter(x; digits=2)
    return string(x, "e", round(log10(abs(x)), digits=digits))
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
    if abs(x) >= 1e3 || abs(x) < 1e-3
        return string(round(x / 10^(round(log10(abs(x)))), digits=digits), "e", round(log10(abs(x))))
    else
        return round(x, digits=digits)
    end
end
