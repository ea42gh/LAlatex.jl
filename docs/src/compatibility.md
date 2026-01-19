# Compatibility

## Julia

- Julia 1.9+ recommended.

## Python

- System Python 3.10+ recommended.
- `sympy` is required when using the SymPy backend.

## Environment variables

- `JULIA_CONDAPKG_BACKEND=Null` to disable Conda.
- `JULIA_PYTHONCALL_EXE=/usr/local/bin/python3` to select the system Python.

## Notes

- For Symbolics + complex rationals, use `mixed_matrix` or `@mixed_matrix`.
