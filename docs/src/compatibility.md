# Compatibility

## Julia

- Julia 1.10.10+ required by package compatibility bounds.

## Python

- System Python 3.10+ recommended.
- `sympy` is required when using the SymPy backend.

## Backend parity checklist

| Feature | Symbolics backend | SymPy backend | Test policy |
| --- | --- | --- | --- |
| Symbol construction and assumptions | Supported by `syms`, `@syms`, `assume!`, and `assumptions` | Supported by `syms`, `syms_sympy`, and `@syms_sympy`; assumptions are forwarded to SymPy | Exercise both backends directly |
| Scalar LaTeX normalization | Supported by the local Symbolics renderer and `normalize_symbolics_latex` | Supported through `sympy.latex` and shared scalar entry normalization | Compare scalar and matrix-entry normalization paths for both backends |
| Matrix rendering | Supported for Symbolics entries mixed with numeric entries | Supported for SymPy entries mixed with numeric entries | Render representative symbolic matrices for both backends |
| Symbolic transforms | Supports display-time `expand`, `factor`, `collect`, and `simplify` where Symbolics provides them | Supports display-time `expand`, `factor`, `collect`, and `simplify` through SymPy | Verify at least expansion for both backends |
| Denominator factoring | Coefficient-level factoring for literal rationals, numeric symbolic coefficients, and explicit scalar division | Coefficient-level factoring via SymPy `together` / `denom` for scalar denominators | Verify scalar division, additive scalar division, and powers that must not factor |
| `lc` sign handling | Supports negative literal and symbolic coefficient extraction | Supports SymPy `could_extract_minus_sign` | Verify signed linear combinations for both backends |
| Exact output snapshots | Canonical Symbolics examples only | Not exact-snapshotted; SymPy formatting is delegated upstream | Keep broad SymPy tests with semantic string checks |

## Environment variables

- `JULIA_CONDAPKG_BACKEND=Null` to disable Conda.
- `JULIA_PYTHONCALL_EXE=/usr/local/bin/python3` to select the system Python.

## Notes

- For Symbolics + complex rationals, use `mixed_matrix` or `@mixed_matrix`.
