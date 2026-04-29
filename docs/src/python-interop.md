# Python interop

LAlatex can interoperate with Python via `PythonCall` (Julia -> Python) and
`juliacall` (Python -> Julia).

## Julia -> Python (PythonCall)

```julia
using LAlatex
using PythonCall
pyimport("sys").executable
```

## Python -> Julia (juliacall)

Install the Python-side bridge before running Python examples:

```bash
python -m pip install juliacall
```

```python
from juliacall import Main as jl
from IPython.display import Latex, display

jl.seval("using LAlatex")
latex = jl.LAlatex.L_show("A = ", [[1, 2], [3, 4]])

display(Latex(latex))
```

If you are working in the `elementary-linear-algebra` notebook environment, a
startup helper file named `10-julia-magic.py` may also define Python-side
helpers such as `l_show(...)` and `L(...)`.

`10-julia-magic.py` is not part of `LAlatex`. It is an external notebook
convenience layer. `LAlatex` itself exposes Julia functions such as
`L_show(...)` and `l_show(...)`, but it does not install Python globals named
`l_show` or `L`.

In that environment, the Python-side helper usage is:

```python
from juliacall import Main as jl
jl.seval("using LAlatex")

A = [[1, 2, 4], [3, 4, 1]]
l_show("A = ", A)
l_show("x = ", 3, L(r";\\quad "), "x^2 = ", 9)
```

## No-conda setup

Ensure the following environment variables are set so PythonCall uses the system Python:

- `JULIA_CONDAPKG_BACKEND=Null`
- `JULIA_PYTHONCALL_EXE=/usr/local/bin/python3`
