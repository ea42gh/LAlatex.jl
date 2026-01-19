# FAQ and troubleshooting

## SymPy import fails

Ensure `sympy` is installed in the Python used by PythonCall.

```julia
using PythonCall
pyimport("sys").executable
```

## Symbolics + complex rationals error

Use `mixed_matrix` or `@mixed_matrix` to avoid ambiguous `promote_rule` errors.

## Text vs math font

Use `L"..."` / `LaTeXString` for math; plain strings are wrapped in `\text{...}`.
