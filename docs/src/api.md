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
- `symbolic_transform` (Symbolics/SymPy display transforms)

### symbolic_transform options

`symbolic_transform(x; kwargs...)` and `L_show(...; symopts=kwargs)` accept:

| Option | Values | Notes |
| --- | --- | --- |
| `simplify` | `true`/`false` | Apply backend simplification. |
| `expand` | `true`/`false` | Expand algebraic products. |
| `factor` | `true`/`false` | Factor algebraic expressions. |
| `collect` | `Symbolics.Num`/`PythonCall.Py`/`nothing` | Collect terms with respect to a variable. |

Use `symopts=(; factor=true)` or `symopts=(factor=true,)` to build a `NamedTuple`.

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
- `set`, `lc`
- `L_interp`
- `apply_function`, `round_value`, `round_matrices`
- `print_np_array_def`
- `L_show(...; symopts=...)` for optional Symbolics/SymPy transforms
- `factor_out_denominator` (returns `(den, scaled)` and expands symbolic entries elementwise)


## Internal API coverage

```@docs
LAlatex.Backend
LAlatex.Backend.get_backend
LAlatex.Backend.set_backend!
LAlatex.Backend.backend_available
LAlatex.SymbolicsBackendImpl.syms_symbolics
LAlatex.SymbolicsBackendImpl.assume_symbolics!
LAlatex.SymbolicsBackendImpl.symbolics_assumptions
```
