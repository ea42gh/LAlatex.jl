```@meta
CurrentModule = LAlatex
```

# LAlatex

Documentation for [LAlatex](https://github.com/ea42gh/LAlatex).

## Install

See the Installation page for Julia + SymPy setup details.

## API cheat sheet

- `L_show(...)` -> LaTeX string
- `l_show(...)` -> `LaTeXString` for display
- `syms(...)`, `@syms` -> symbols (Symbolics or SymPy)
- `set_backend!(:symbolics | :sympy)` -> backend switch

## 1.0 migration

- `Backend.backend_available(...)` was replaced by
  `Backend.backend_usable(...)`.
- `Backend.backend_usable(...)` is a runtime usability probe and may initialize
  Python/import `sympy`.
- Release tags now follow the package version directly: `1.0.0` -> `v1.0.0`.

See the Quickstart page for a minimal setup and first render.
See the Upgrading page for the 1.0 migration notes and current release policy.

See the Examples page for backend switching, assumptions, HTML helpers, and LaTeX helpers.
See the Display policy page for `cases` and `aligned` rendering rules.

## Gallery

<table width="100%">
  <tr>
    <th>Column vectors</th>
    <th>BlockArray (odd values)</th>
  </tr>
  <tr>
    <td><img src="assets/column_vectors.svg" alt="Column vectors"></td>
    <td><img src="assets/blockarray_colorize.svg" alt="BlockArray odd values"></td>
  </tr>
</table>

<table width="100%">
  <tr>
    <th>SymPy linear combination</th>
  </tr>
  <tr>
    <td><img src="assets/sympy_lc.svg" alt="SymPy linear combination"></td>
  </tr>
</table>

## Troubleshooting

- **SymPy import fails**: Ensure `sympy` is installed in the Python used by PythonCall. Check with `import_sympy()` or `PythonCall.pyimport("sys").executable`.
- **Mixed symbolic/numeric matrices**: Use ordinary Julia literals for homogeneous matrices. Use `mixed_matrix` or `@mixed_matrix` only when a heterogeneous symbolic/numeric matrix fails during construction because Julia tries to promote all entries to one type.
- **Math font vs text font**: Use `L"..."`/`LaTeXString` for math; plain strings are wrapped in `\\text{...}` by `L_show`.
- **SymPy tests skipped**: Set `JULIA_PYTHONCALL_EXE` to a Python that has SymPy installed.

## Documentation notebooks

- `docs/src/notebooks/LAlatex_basics.ipynb`: project setup, backend switching, assumptions, HTML helpers, and formatters.
- `docs/src/notebooks/LAlatex_L_show_Guide.ipynb`: detailed `L_show`/`l_show` usage across scalars, strings, matrices, block arrays, and per-element styling.
- `docs/src/notebooks/LAlatex_cases_Guide.ipynb`: focused guide to `cases(...)` syntax, row policy, and propagated display options.
- `docs/src/notebooks/LAlatex_aligned_Guide.ipynb`: focused guide to `aligned(...)` row forms, implicit alignment markers, and propagated display options.
- `docs/src/notebooks/LAlatex_HTML_Utilities.ipynb`: HTML helpers with `show_html`, `pr`, and side-by-side display.
- `docs/src/notebooks/LAlatex_from_Python.ipynb`: render Python expressions via Julia `LAlatex` using `juliacall`.

See the API page for generated docstrings and symbol index.
