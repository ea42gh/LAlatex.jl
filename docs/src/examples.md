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

## Symbolic display controls

Use `symbolic_transform` directly, or pass `symopts` to `L_show`/`l_show` for display-time transforms.

```julia
set_backend!(:symbolics)
x, y = syms(:x, :y)
expr = (x + y)^2

L_show(expr; symopts=(expand=true,))
```

Symbolic coefficients also work in linear combinations. In signed mode,
coefficients that are structurally negative are displayed with a leading minus,
while mixed-sign coefficients stay parenthesized with their own signs.

```julia
set_backend!(:symbolics)
x, y = syms(:x, :y)

coeffs = [-(x + y), x - y, 1]
vectors = [x y x + y]

l_show(lc(coeffs, vectors; sign_policy=:signed))
```

## Cases and piecewise displays

Use `cases` for piecewise definitions. Each entry can be written as
`value => condition` or `(value, condition)`, and each value is rendered with
the same display policy as `L_show`.

```julia
@syms x y

L_show(
    "T(v) = ",
    cases(
        [x, 0] => L"v \in \operatorname{span}\{e_1\}",
        ([0, y], "otherwise"),
    ),
)
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

Rendered output (LaTeX strings from `LAlatex_examples.ipynb`):

```text
$\text{Tuple of Column and Row vectors: } \begin{bmatrix}
1 & 2 & 3 \\
\end{bmatrix},\begin{bmatrix}
4 \\
5 \\
6 \\
\end{bmatrix}$
```

```text
$(\xi) \Leftrightarrow\;\;  -  \left(2 \alpha_{2} + 4 \alpha_{5} + 7 \alpha_{6}\right)\left(\begin{array}{r}
-2 \\
0 \\
-4 \\
4 \\
\end{array}\right)  +  \alpha_{2}\left(\begin{array}{r}
-4 \\
0 \\
-8 \\
8 \\
\end{array}\right)  +  \left(2 \alpha_{5} + 3 \alpha_{6}\right)\left(\begin{array}{r}
2 \\
1 \\
3 \\
-1 \\
\end{array}\right)  +  \left(\begin{array}{r}
4 \\
-2 \\
10 \\
-14 \\
\end{array}\right)  -  \alpha_{6}\left(\begin{array}{r}
8 \\
-3 \\
19 \\
-25 \\
\end{array}\right)  = 0$
```

```text
$\text{Colorize odd values,  A=} \left(\begin{array}{rr|r}
\textcolor{red}{1} & 2 & 4 \\ \hline
\textcolor{red}{3} & 4 & \textcolor{red}{5} \\
\end{array}\right)$
```

`factor_out_denominator` returns a common denominator and a scaled matrix. Symbolic entries are expanded elementwise after scaling:

```julia
den, scaled = factor_out_denominator(F^2)
display(l_show(scaled))
```

For symbolic matrices, denominator factoring is coefficient-level. Literal rational entries, numeric symbolic coefficients, and explicit scalar divisions such as `x / 2` contribute denominators. Rationals inside symbolic powers or functions, such as `(3//10)^n`, stay inside the expression and are not factored out as a matrix-wide `1//10`. Non-scalar symbolic denominators such as `x / (2y)` also do not contribute a display-wide factor.

Complex symbolic entries are handled the same way. Denominators in symbolic real and imaginary coefficients contribute to the display-wide factor, and the scaled complex symbolic entries render without embedded equation environments:

```julia
@syms x y

C = mixed_matrix(
    (x / 2 + im * (y / 3), 1//5),
    (x, y),
)

den, scaled = factor_out_denominator(C)
@assert den == 30
l_show("scaled=", scaled)
```

This factors out `1//30`; the first entry of `scaled` is rendered as `15 x + 10 y\mathit{i}`.

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
- `docs/src/quickstart.md`
- `docs/src/python-interop.md`
- `docs/src/faq.md`
- `docs/src/compatibility.md`
- `docs/src/notebooks/LAlatex_basics.ipynb`
- `docs/src/notebooks/LAlatex_L_show_Guide.ipynb`
- `docs/src/notebooks/LAlatex_HTML_Utilities.ipynb`
- `docs/src/notebooks/LAlatex_from_Python.ipynb`
