"""
    combine_formatters(formatters, x, i, j, formatted_x) -> String

Apply a list of formatter functions sequentially to an entry.
"""
function combine_formatters(formatters, x, i, j, formatted_x)
    result = formatted_x
    for formatter in formatters
        result = formatter(x, i, j, result)
    end
    return result
end

"""
    tril_formatter(x, i, j, formatted_x;
                   k=0, color="red",
                   c1=1, c2=typemax(Int),
                   r1=1, r2=typemax(Int)) -> String

Highlight entries on or below diagonal `k` within an optional row/column window.
"""
function tril_formatter(x, i, j, formatted_x;
                        k::Int = 0,
                        color::String = "red",
                        c1::Int = 1,
                        c2::Int = typemax(Int),
                        r1::Int = 1,
                        r2::Int = typemax(Int))
    if (i >= j - k) && (c1 <= j <= c2) && (r1 <= i <= r2)
        return "\\textcolor{$color}{$formatted_x}"
    else
        return formatted_x
    end
end

"""
    block_formatter(x, i, j, formatted_x; r1=1, r2=1, c1=1, c2=1) -> String

Highlight entries inside a rectangular block using a red text color.
"""
function block_formatter(x, i, j, formatted_x; r1=1, r2=1, c1=1, c2=1)
    if (r1 <= i <= r2) && (c1 <= j <= c2)
        return "\\textcolor{red}{$formatted_x}"
    else
        return formatted_x
    end
end

"""
    diagonal_blocks_formatter(x, i, j, formatted_x;
                              blocks::Vector{Int},
                              colors::Vector{String}=["red"]) -> String

Highlight entries in diagonal blocks; negative sizes skip highlighting.
"""
function diagonal_blocks_formatter(x, i, j, formatted_x;
                                   blocks::Vector{Int},
                                   colors::Vector{String} = ["red"])
    sizes = abs.(blocks)
    limits = cumsum(sizes)
    starts = [1; limits[1:end-1] .+ 1]
    nblocks = length(blocks)

    block_id = findfirst(k -> (starts[k] <= i <= limits[k] &&
                               starts[k] <= j <= limits[k]),
                         1:nblocks)

    block_id === nothing && return formatted_x
    blocks[block_id] < 0 && return formatted_x

    color = colors[mod(block_id - 1, length(colors)) + 1]
    return "\\textcolor{$color}{$formatted_x}"
end


"""
    rowechelon_formatter(x, i, j, formatted_x;
                         pivots::AbstractVector{<:Integer},
                         color::String="red") -> String

Highlight pivot entries and all entries to the right on pivot rows for row-echelon displays.

`pivots[k]` is the pivot column for row `k`. Use `0` or a negative value to indicate
that a row has no pivot.
"""
function rowechelon_formatter(x, i, j, formatted_x;
                              pivots::AbstractVector{<:Integer},
                              color::String="red")::String
    if 1 <= i <= length(pivots)
        pivot_col = pivots[i]
        if pivot_col > 0 && j >= pivot_col
            return "\\textcolor{$color}{$formatted_x}"
        end
    end
    return formatted_x
end
