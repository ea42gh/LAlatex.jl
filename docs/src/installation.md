# Installation

LAlatex is a Julia package. For SymPy support it relies on PythonCall.

## Julia install

```julia
using Pkg
Pkg.add("LAlatex")
```

## SymPy (optional)

If you want the SymPy backend, install SymPy in the Python that PythonCall uses.

Recommended: point PythonCall at a system Python that already has SymPy.

```bash
python3 -m pip install sympy
```

```bash
export JULIA_PYTHONCALL_EXE=/usr/local/bin/python3
export JULIA_CONDAPKG_BACKEND=Null
```

## Quick verification

```julia
using LAlatex
using PythonCall

PythonCall.pyimport("sympy")
set_backend!(:sympy)
LAlatex.@syms x y
```

If SymPy is not needed, skip the Python steps and use the default Symbolics backend.
