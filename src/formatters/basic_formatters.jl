"""
    bold_formatter(x, i, j, formatted_x) -> String

Wrap the formatted entry in `\\boldsymbol{}`.
"""
function bold_formatter(x, i, j, formatted_x)
    return "\\boldsymbol{$formatted_x}"
end

"""
    italic_formatter(x, i, j, formatted_x) -> String

Wrap the formatted entry in `\\mathit{}`.
"""
function italic_formatter(x, i, j, formatted_x)
    return "\\mathit{$formatted_x}"
end

"""
    color_formatter(x, i, j, formatted_x; color="red") -> String

Wrap the formatted entry in `\\textcolor{color}{}`.
"""
function color_formatter(x, i, j, formatted_x; color="red")
    return "\\textcolor{$color}{$formatted_x}"
end

"""
    conditional_color_formatter(x, i, j, formatted_x) -> String

Color positive entries green, negative entries red, and leave zero unchanged.
"""
function conditional_color_formatter(x, i, j, formatted_x)
    if x > 0
        return "\\textcolor{green}{$formatted_x}"
    elseif x < 0
        return "\\textcolor{red}{$formatted_x}"
    else
        return formatted_x
    end
end

"""
    highlight_large_values(x, i, j, formatted_x; threshold=10) -> String

Wrap entries with absolute value above `threshold` in `\\boxed{}`.
"""
function highlight_large_values(x, i, j, formatted_x; threshold=10)
    if abs(x) > threshold
        return "\\boxed{$formatted_x}"
    else
        return formatted_x
    end
end

"""
    underline_formatter(x, i, j, formatted_x) -> String

Wrap the formatted entry in `\\underline{}`.
"""
function underline_formatter(x, i, j, formatted_x)
    return "\\underline{$formatted_x}"
end

"""
    overline_formatter(x, i, j, formatted_x) -> String

Wrap the formatted entry in `\\overline{}`.
"""
function overline_formatter(x, i, j, formatted_x)
    return "\\overline{$formatted_x}"
end
