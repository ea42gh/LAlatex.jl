# Changelog

## Unreleased

- Added Windows and macOS CI coverage alongside the Ubuntu matrix.
- Added structural and executed notebook smoke checks to the docs workflow.
- Documented 1.0 migration, release policy, and release checklist expectations.
- Added a lightweight benchmark script at `perf/benchmark.jl` for first-call render timing.
- Fixed Symbolics expression rendering in `L_show` so symbolic functions such as `exp(-3t)` no longer produce embedded `equation` environments inside matrices.
- Preserved rational-power base parentheses, including outputs such as `L_show((3//10)^n)`.
- Clarified and hardened symbolic denominator factoring: denominators are factored from literal rationals, numeric symbolic coefficients, and explicit scalar divisions, but not from powers, functions, or non-scalar symbolic denominators.
- Added support for denominator factoring in block vectors while preserving `BlockArray` dimensionality and block axes.
- Stabilized empty rational vector and matrix denominator factoring by returning `(1, A)` unchanged.
- Broadened rational denominator factoring beyond `Rational{Int}`, including `Rational{BigInt}` and complex rational arrays.
- Normalized complex symbolic rendering after denominator scaling so complex entries with symbolic real or imaginary parts avoid embedded `equation` environments.
- Added focused Symbolics/SymPy parity, exact snapshot, export, block array, empty rational array, broad rational, and complex symbolic denominator tests.
