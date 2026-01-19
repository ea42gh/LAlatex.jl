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

```julia
set_backend!(:symbolics)
x, y = syms(:x, :y)
M = mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
L_show(M)
```

## Python interop (optional)

```julia
using PythonCall
pyimport("sys").executable
```
