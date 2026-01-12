# API

## Backends

- `set_backend!` / `get_backend`
- `syms`, `@syms`
- `syms_sympy`, `@syms_sympy` (SymPy-only)
- `mixed_matrix`, `@mixed_matrix`

Note: use `mixed_matrix`/`@mixed_matrix` when mixing Symbolics/SymPy symbols with complex rationals,
otherwise Julia may throw an ambiguous `promote_rule` error when constructing a matrix literal.

## Assumptions (Symbolics metadata)

- `assume!`
- `assumptions`

## HTML helpers

- `to_html`, `show_html`, `pr`
- `capture_output`
- `show_side_by_side_html`, `show_side_by_side`

## LaTeX helpers

- `to_latex`

## Formatter helpers

- `bold_formatter`, `italic_formatter`, `color_formatter`
- `conditional_color_formatter`, `highlight_large_values`
- `underline_formatter`, `overline_formatter`
- `combine_formatters`
- `scientific_formatter`, `percentage_formatter`, `exponential_formatter`
- `tril_formatter`, `block_formatter`, `diagonal_blocks_formatter`
- `rowechelon_formatter`

## LaTeX display helpers

- `L_show`
- `l_show`
- `py_show`
- `set`, `lc`
- `L_interp`
- `apply_function`, `round_value`, `round_matrices`
- `print_np_array_def`
