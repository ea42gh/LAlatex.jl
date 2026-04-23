# FAQ and troubleshooting

## SymPy import fails

Ensure `PythonCall` is installed in Julia and `sympy` is installed in the
Python used by PythonCall.

```julia
using PythonCall
pyimport("sys").executable
```

## Symbolics + complex rationals error

This usually happens while Julia is constructing a matrix literal, before
LAlatex can render it. Julia tries to promote every entry to one common element
type, which can fail for mixtures such as Symbolics entries, SymPy entries,
exact rationals, and complex rationals.

Use `mixed_matrix` or `@mixed_matrix` as a targeted construction helper:

```julia
F = mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
G = @mixed_matrix [1//2 x; (1 + im)//3 2*y]
```

For homogeneous numeric or symbolic matrices, prefer ordinary Julia literals.

## Text vs math font

Use `L"..."` / `LaTeXString` for math; plain strings are wrapped in `\text{...}`.
