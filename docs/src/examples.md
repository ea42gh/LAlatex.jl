# Examples

## Backend switching

`syms` and `LAlatex.@syms` follow the active backend. The default is Symbolics.

```julia
using LAlatex

LAlatex.@syms x y
set_backend!(:sympy)
LAlatex.@syms a :real => true :positive => true
set_backend!(:symbolics)
LAlatex.@syms b
```

You can also select a backend per call:

```julia
x = syms(:x; backend=:sympy, real=true)
```

## Symbolics assumptions

Symbolics does not accept SymPy-style keyword assumptions directly, so LAlatex stores them as metadata.

```julia
LAlatex.@syms t :real => true
assumptions(t)
```

## SymPy helpers

Explicit SymPy helpers are available when SymPy can be imported:

```julia
@syms_sympy p :real => true :positive => true
q = syms_sympy(:q)
```

## Mixed matrices

Use `mixed_matrix` or `@mixed_matrix` to avoid promotion errors when mixing
Symbolics/SymPy symbols with complex rationals.

```julia
set_backend!(:symbolics)
x, y = syms(:x, :y)
F = mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
G = @mixed_matrix [1//2 x; (1 + im)//3 2*y]
```

Common pitfall:

```julia
# This fails because Julia tries to promote element types first:
F_bad = [1//2 x; (1 + im)//3 2*y]
```

## HTML helpers

```julia
show_html("hello"; color="darkred")
show_side_by_side(["left", "right"], ["A", "B"])
```

## LaTeX helpers

```julia
to_latex(3//4)
```

## Formatter helpers

```julia
formatted = rowechelon_formatter(1, 2, 4, "x"; pivots=[1, 3])
```

## LaTeX display helpers

```julia
L_show(1, " = ", [1 2; 3 4])
display(l_show(1, " = ", [1 2; 3 4]))
```

## Array styles

Use `arraystyle` to select the LaTeX environment and delimiters:

| Style | Output |
| --- | --- |
| `:parray` | `\\left(\\begin{array} ... \\end{array}\\right)` |
| `:barray` | `\\left[\\begin{array} ... \\end{array}\\right]` |
| `:Barray` | `\\left\\{\\begin{array} ... \\end{array}\\right\\}` |
| `:Varray` | `\\left\\Vert\\begin{array} ... \\end{array}\\right\\Vert` |
| `:varray` | `\\left\\vert\\begin{array} ... \\end{array}\\right\\vert` |
| `:pmatrix` | `\\begin{pmatrix} ... \\end{pmatrix}` |
| `:bmatrix` | `\\begin{bmatrix} ... \\end{bmatrix}` |
| `:Bmatrix` | `\\begin{Bmatrix} ... \\end{Bmatrix}` |
| `:vmatrix` | `\\begin{vmatrix} ... \\end{vmatrix}` |
| `:Vmatrix` | `\\begin{Vmatrix} ... \\end{Vmatrix}` |

## Utility helpers

```julia
tpl = L_interp(LaTeXString("\\mathbb{R}^{\\$(n)}"), Dict("n" => 3))
print_np_array_def([1, 2, 3]; nm="v")
```

## Notebook

See the notebooks in `docs/src/notebooks/` for runnable walkthroughs:
- `docs/src/notebooks/LAlatex_basics.ipynb`
- `docs/src/notebooks/LAlatex_L_show_Guide.ipynb`
- `docs/src/notebooks/LAlatex_HTML_Utilities.ipynb`
