# Quickstart

## Install and load

```julia
using LAlatex
```

## First render

```julia
L_show("A = ", [1 2; 3 4])
display(l_show("A = ", [1 2; 3 4]))
```

## Backend selection

```julia
set_backend!(:symbolics)
@syms x y
L_show(x + y)

set_backend!(:sympy)
@syms a :real => true
L_show(a^2 + 2a + 1)
```

## Mixed matrices

Most matrices should use ordinary Julia literals. Reach for `mixed_matrix` only
when Julia cannot construct the matrix because it tries to promote mixed entry
types first.

```julia
set_backend!(:symbolics)
x, y = syms(:x, :y)

# This preserves the exact entries without type promotion.
M = mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
L_show(M)
```

The macro form keeps matrix-literal syntax while avoiding promotion:

```julia
M = @mixed_matrix [1//2 x; (1 + im)//3 2*y]
```

## Python interop (optional)

```julia
using PythonCall
pyimport("sys").executable
```

## Benchmarking

From the repository root, run:

```julia
julia --project=. perf/benchmark.jl
```

This gives a lightweight view of first-call rendering cost for the main display
paths and reports whether the SymPy-backed render path was exercised or skipped.
