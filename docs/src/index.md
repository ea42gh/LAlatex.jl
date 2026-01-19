```@meta
CurrentModule = LAlatex
```

# LAlatex

Documentation for [LAlatex](https://github.com/ea42gh/LAlatex.jl).

See the Quickstart page for a minimal setup and first render.

See the Examples page for backend switching, assumptions, HTML helpers, and LaTeX helpers.

## Troubleshooting

- **SymPy import fails**: Ensure `sympy` is installed in the Python used by PythonCall. Check with `PythonCall.pyimport("sys").executable`.
- **Symbolics + complex rationals**: Use `mixed_matrix` or `@mixed_matrix` when mixing Symbolics/SymPy symbols with complex rationals to avoid ambiguous `promote_rule` errors.
- **Math font vs text font**: Use `L"..."`/`LaTeXString` for math; plain strings are wrapped in `\\text{...}` by `L_show`.
- **SymPy tests skipped**: Set `JULIA_PYTHONCALL_EXE` to a Python that has SymPy installed.

## Documentation notebooks

- `docs/src/notebooks/LAlatex_basics.ipynb`: project setup, backend switching, assumptions, HTML helpers, and formatters.
- `docs/src/notebooks/LAlatex_L_show_Guide.ipynb`: detailed `L_show`/`l_show` usage across scalars, strings, matrices, block arrays, and per-element styling.
- `docs/src/notebooks/LAlatex_HTML_Utilities.ipynb`: HTML helpers with `show_html`, `pr`, and side-by-side display.
- `docs/src/notebooks/LAlatex_from_Python.ipynb`: render Python expressions via Julia `LAlatex` using `juliacall`.

```@index
```

```@autodocs
Modules = [LAlatex]
```
