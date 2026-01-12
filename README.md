# LAlatex

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ea42gh.github.io/LAlatex.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ea42gh.github.io/LAlatex.jl/dev/)
[![Build Status](https://github.com/ea42gh/LAlatex.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ea42gh/LAlatex.jl/actions/workflows/CI.yml?query=branch%3Amain)

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
