# LAlatex

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ea42gh.github.io/LAlatex/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ea42gh.github.io/LAlatex/dev/)
[![Build Status](https://github.com/ea42gh/LAlatex/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ea42gh/LAlatex/actions/workflows/CI.yml?query=branch%3Amain)

Why LAlatex?
- It keeps linear algebra notation consistent across lectures, notes, and notebooks.
- It renders mixed text+math without hand-written LaTeX.
- It supports block structure and symbolic backends out of the box.

Gallery (rendered output):

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

LAlatex turns Julia objects into compact, readable LaTeX. It is designed for
teaching and visualization: matrices, block matrices, linear combinations,
symbolic expressions, and mixed text+math all render with consistent styling.
If you teach linear algebra or build math-heavy notebooks, this keeps your
notation consistent without hand-writing LaTeX.

Highlights:
- `L_show(...)` returns a LaTeX string ready for Markdown, Documenter, or PDF.
- `l_show(...)` returns a `LaTeXString` for inline display in notebooks.
- Works with numbers, arrays, `BlockArray`s, `LinearCombination`s, and tuples.
- Supports Symbolics and SymPy backends for symbolic algebra.

Install:

```julia
using Pkg
Pkg.add("LAlatex")
```

API cheat sheet:
- `L_show(...)` -> LaTeX string
- `l_show(...)` -> `LaTeXString` for display
- `syms(...)`, `@syms` -> symbols (Symbolics or SymPy)
- `set_backend!(:symbolics | :sympy)` -> backend switch

Supported inputs:
- Numbers and rationals
- Vectors, matrices, and tuples
- `BlockArray` and block-structured data
- `LinearCombination` objects
- Symbolics and SymPy expressions

Quick start:

```julia
using LAlatex

A = [1 2; 3 4]
println(L_show("A = ", A))
l_show("A = ", A)
```

Python interop:

```python
# pip install juliacall
from juliacall import Main as jl
jl.seval("using LAlatex")
print(jl.LAlatex.L_show("A = ", [[1, 2], [3, 4]]))
```

Notebook highlight:
- `docs/src/notebooks/LAlatex_L_show_Guide.ipynb`

Linear combinations and mixed text/math:

```julia
s = [2, -1, 3]
X = [[1, 0], [0, 1], [1, 1]]
l_show("x = ", lc(s, X))
```

Mini gallery:

```julia
using LAlatex
using BlockArrays

# Column vectors
v1 = [1, 2, 3]
v2 = [4 5 6]
t8a = (v1', v2')
l_show("Tuple of Column and Row vectors: ", t8a, arraystyle=:bmatrix)

# SymPy backend + linear combination
LAlatex.set_backend!(:sympy)
α = [syms("α_$i"; real=true) for i in 1:6]
s  = [ -2α[2] + 4α[5] + 7α[6],  α[2],  0,  2α[5] + 3α[6],  1,  -α[6] ]
X  = [ -2 -4  -2   2   4    8
        0  0  -1   1  -2   -3
       -4 -8  -3   3  10   19
        4  8   0  -1 -14  -25 ]
l_show( L"(\\xi) \\Leftrightarrow\\;\\;", lc(s, X; sign_policy=:signed, omit_one=true, drop_zero=true), "= 0")

# BlockArray with odd entries colored
A = BlockArray([1 2 4; 3 4 5], [1, 1], [2, 1])
function color_odd_numbers(x, i, j, latex_str)
    return isodd(x) ? "\\textcolor{red}{$latex_str}" : latex_str
end
display(l_show("Colorize odd values,  A=", A; per_element_style=color_odd_numbers))
```

Rendered output (LaTeX strings):

```text
$\text{Colorize odd values,  A=} \left(\begin{array}{rr|r}
\textcolor{red}{1} & 2 & 4 \\ \hline
\textcolor{red}{3} & 4 & \textcolor{red}{5} \\
\end{array}\right)$
```

## Backends (Symbolics and SymPy)

`syms` and `LAlatex.@syms` create symbols using the currently selected backend. The default backend is Symbolics.

```julia
using LAlatex

LAlatex.@syms x y                 # Symbolics symbols
set_backend!(:sympy)
LAlatex.@syms a :real => true     # SymPy symbols
set_backend!(:symbolics)
LAlatex.@syms b                  # Symbolics again
```

You can also select a backend per call:

```julia
x = syms(:x; backend=:sympy, real=true)
```

Explicit SymPy helpers are available:

```julia
@syms_sympy p :real => true :positive => true
q = syms_sympy(:q)
```

## Python setup

SymPy support is optional. `PythonCall` is bundled with the package; point it
at a system Python with SymPy installed if needed:

```bash
python3 -m pip install sympy
```

```bash
export JULIA_PYTHONCALL_EXE=/path/to/python
```

## 1.0 migration

- `Backend.backend_available(...)` was removed. Use `Backend.backend_usable(...)`.
- `Backend.backend_usable(...)` is a runtime usability probe. For the SymPy
  backend, it may initialize Python and attempt to import `sympy`.
- Use `import_sympy()` when you want explicit initialization or a more direct
  import failure path for diagnostics.
- Supported release tags now follow the package version directly:
  `Project.toml` `1.0.0` corresponds to tag `v1.0.0`.

Example:

```julia
using LAlatex

if LAlatex.Backend.backend_usable(LAlatex.Backend.SymPyBackend)
    set_backend!(:sympy)
end
```

## Release policy

- `Project.toml` is the authoritative package version.
- Release tags follow the package version exactly: `1.0.0` -> `v1.0.0`.
- Docs publish from `main` after the matching changes are green in CI.
- Release steps and verification commands live in [RELEASING.md](RELEASING.md).
