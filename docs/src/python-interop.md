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

```python
from juliacall import Main as jl
from IPython.display import Latex, display

jl.seval("using LAlatex")
latex = jl.LAlatex.L_show("A = ", [[1, 2], [3, 4]])

display(Latex(latex))
```

## No-conda setup

Ensure the following environment variables are set so PythonCall uses the system Python:

- `JULIA_CONDAPKG_BACKEND=Null`
- `JULIA_PYTHONCALL_EXE=/usr/local/bin/python3`
