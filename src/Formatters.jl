include("formatters/basic_formatters.jl")
include("formatters/numeric_formatters.jl")
include("formatters/matrix_formatters.jl")

export bold_formatter,
    italic_formatter,
    color_formatter,
    conditional_color_formatter,
    highlight_large_values,
    underline_formatter,
    overline_formatter,
    combine_formatters,
    scientific_formatter,
    percentage_formatter,
    exponential_formatter,
    tril_formatter,
    block_formatter,
    diagonal_blocks_formatter,
    echelon_pivot_formatter
