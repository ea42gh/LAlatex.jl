# Upgrading

## Upgrading to 1.0

`LAlatex` now treats the package version in `Project.toml` as the authoritative
release version. Package version `1.0.0` corresponds to the repository tag
`v1.0.0`.

### Backend usability probe

The old public helper:

- `Backend.backend_available(...)`

was replaced by:

- `Backend.backend_usable(...)`

`Backend.backend_usable(...)` is a runtime usability probe, not a static install
check. For the SymPy backend it may initialize Python and attempt to import
`sympy`.

Use `import_sympy()` when you want explicit initialization and a direct error
path for SymPy import failures.

### Python and SymPy expectations

The default Symbolics backend does not require Python. SymPy remains optional.
When you want the SymPy backend, make sure the Python used by `PythonCall` has
`sympy` installed and, in CI or a no-Conda setup, point `JULIA_PYTHONCALL_EXE`
at that Python explicitly.

### Release workflow

Releases are expected to follow this sequence:

1. update `Project.toml`
2. push the release-preparation commit
3. wait for `CI` and `Docs` to go green
4. create the matching tag `vX.Y.Z`
5. publish/update the GitHub Release object

See `RELEASING.md` for the current checklist.
