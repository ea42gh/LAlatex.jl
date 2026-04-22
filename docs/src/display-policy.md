# Display Policy

This page documents the display policy for structured LaTeX helpers. These
helpers do not parse raw LaTeX equations. They render Julia values through the
same `L_show` machinery used for scalars, vectors, matrices, symbolic
expressions, strings, and `LaTeXString`s.

## Text and math cells

Plain Julia strings are rendered as text:

```julia
L_show("otherwise")
```

Use `LaTeXString`s for math fragments:

```julia
L_show(L"x \in \mathcal{N}(A)")
```

This distinction also applies inside `cases` and `aligned`.

## Cases

Use `cases` for piecewise definitions. Each entry may be written as a pair:

```julia
cases(value => condition)
```

or as a two-tuple:

```julia
cases((value, condition))
```

Each value and condition is rendered through the normal `L_show` policy.
Vectors render as column vectors, matrices render as matrices, symbolic
expressions honor `symopts`, and plain strings render as `\text{...}`.

Example:

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

The current `cases` row policy is:

```latex
value, & condition \\
```

That means `cases` inserts the comma before the condition and the alignment
marker before the condition column. Users should not add `&` manually.

## Aligned

Use `aligned` for derivations, equation chains, and equivalence chains. Each
row may be a vector, tuple, or pair.

Vector row:

```julia
aligned([L"Ax", L"=", b])
```

Tuple row:

```julia
aligned((L"x", L"\in", L"\mathcal{N}(A)"))
```

Pair row:

```julia
aligned(L"Ax" => b)
```

For vector and tuple rows, every row cell is rendered with `L_show` and joined
with implicit LaTeX alignment markers:

```latex
cell_1 & cell_2 & cell_3 \\
```

For pair rows, `aligned(left => right)` is equivalent to:

```julia
aligned((left, L"=", right))
```

so it renders as:

```latex
left & = & right \\
```

Users should provide row cells and should not include `&` manually. If raw
LaTeX alignment is needed, pass a complete `LaTeXString` directly to `L_show`
instead of using `aligned`.

Example:

```julia
@syms x y

L_show(
    aligned(
        [L"Ax", L"=", [x, y]],
        (L"x", L"\in", L"\mathcal{N}(A)"),
        L"\dim\mathcal{N}(A)" => L"n - \operatorname{rank}(A)",
    ),
)
```

## Shared options

`cases` and `aligned` propagate display options into their cells:

- `arraystyle`
- `number_formatter`
- `per_element_style`
- `factor_out`
- `symopts`
- `color`

For example:

```julia
L_show(
    aligned([(x + y)^2, L"=", x]);
    symopts=(expand=true,),
)
```

The symbolic expression is expanded before the aligned row is rendered.

## Invalid rows

`cases` entries must be pairs or two-tuples. `aligned` rows must be pairs,
tuples, or vectors, and empty rows are rejected.

