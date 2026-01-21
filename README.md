# LAlatex

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ea42gh.github.io/LAlatex.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ea42gh.github.io/LAlatex.jl/dev/)
[![Build Status](https://github.com/ea42gh/LAlatex.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ea42gh/LAlatex.jl/actions/workflows/CI.yml?query=branch%3Amain)

LAlatex turns Julia objects into compact, readable LaTeX. It is designed for
teaching and visualization: matrices, block matrices, linear combinations,
symbolic expressions, and mixed text+math all render with consistent styling.

Highlights:
- `L_show(...)` returns a LaTeX string ready for Markdown, Documenter, or PDF.
- `l_show(...)` returns a `LaTeXString` for inline display in notebooks.
- Works with numbers, arrays, `BlockArray`s, `LinearCombination`s, and tuples.
- Supports Symbolics and SymPy backends for symbolic algebra.

Quick start:

```julia
using LAlatex

A = [1 2; 3 4]
println(L_show("A = ", A))
l_show("A = ", A)
```

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

# Matrix
A = [1 2 3; 4 5 6]
l_show("A = ", A)

# QR-style block layout
Q = [1 0; 0 1]
R = [2 1; 0 3]
qr_block = BlockArray([Q zeros(2,2); zeros(2,2) R], [2,2], [2,2])
l_show("Q R = ", qr_block; arraystyle=:barray)

# Eigen table (values and eigenvectors)
eigvals = [2, -1]
eigvecs = [1 0; 0 1]
eig_table = BlockArray([eigvals'; eigvecs], [1,2], [2])
l_show("eig = ", eig_table; arraystyle=:barray)
```

Rendered output (LaTeX strings):

```text
$\text{A = } \left(\begin{array}{rrr}
1 & 2 & 3 \\
4 & 5 & 6 \\
\end{array}\right)$
```

```text
$\text{Q R = } \left[\begin{array}{rr|rr}
1 & 0 & 0 & 0 \\
0 & 1 & 0 & 0 \\ \hline
0 & 0 & 2 & 1 \\
0 & 0 & 0 & 3 \\
\end{array}\right]$
```

```text
$\text{eig = } \left[\begin{array}{rr}
2 & -1 \\ \hline
1 & 0 \\
0 & 1 \\
\end{array}\right]$
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

SymPy is provided via PythonCall. If needed, point PythonCall at a system Python with SymPy installed:

```bash
export JULIA_PYTHONCALL_EXE=/path/to/python
```
