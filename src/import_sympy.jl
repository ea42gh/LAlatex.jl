const _sympy = Ref{Any}(nothing)
# ---------------------------------------------------------------------------------------------
"""
    _python_exe_hint() -> Union{String,Nothing}

Return the Python executable used by PythonCall, when available.
"""
function _python_exe_hint()
    # PythonCall exposes the Python executable via its runtime; keep robust.
    # If this fails for some future API change, we still emit the base guidance.
    try
        pc = _ensure_pythoncall()
        pc === nothing && return nothing
        return String(Base.invokelatest(pc.pyimport, "sys").executable)
    catch
        return nothing
    end
end

# ---------------------------------------------------------------------------------------------
"""
    import_sympy() -> Py

Import and cache the Python module `sympy`. Provides an actionable error if unavailable.
"""
function import_sympy()
    if _sympy[] === nothing
        try
            pc = _ensure_pythoncall()
            pc === nothing && error("PythonCall is not available in the current context.")
            _sympy[] = Base.invokelatest(pc.pyimport, "sympy")
        catch err
            exe = _python_exe_hint()
            exe_msg = exe === nothing ? "" : "PythonCall is currently using: $exe\n\n"

            error(
                exe_msg *
                "Could not import Python module `sympy`.\n\n" *
                "Fix options (without CondaPkg):\n" *
                "  1) Install sympy into the Python environment used by PythonCall:\n" *
                "       python -m pip install sympy\n" *
                "  2) Or point PythonCall at a Python that already has sympy by setting:\n" *
                "       JULIA_PYTHONCALL_EXE=/path/to/python\n\n" *
                "Original error:\n$err"
            )
        end
    end
    return _sympy[]
end

# ---------------------------------------------------------------------------------------------
"""
    syms_sympy(names...; kwargs...)

Create one or more SymPy symbols.

Arguments are forwarded to `sympy.symbols`. Multiple names return a tuple.
Keyword arguments are passed directly to SymPy.

Examples
```julia
x = syms_sympy(:x)
x, y = syms_sympy(:x, :y; real=true)
"""
function syms_sympy(names...; kwargs...)
    sympy = import_sympy()
    pc = _ensure_pythoncall()
    # Avoid Py getproperty world-age issues by using pygetattr directly.
    symbols = Base.invokelatest(pc.pygetattr, sympy, "symbols")
    strnames = map(n -> n isa Symbol ? String(n) : String(n), names)
    isempty(strnames) && throw(ArgumentError("syms_sympy expects at least one name"))
    joined = length(strnames) == 1 ? strnames[1] : join(strnames, " ")
    return Base.invokelatest(symbols, joined; kwargs...)
end

# ---------------------------------------------------------------------------------------------
"""
    @syms_sympy x y z [(:key => value)...]

Create and bind SymPy symbols to Julia variables.

Options must be given as `key => value` pairs and apply to all symbols.

Examples
```julia
@syms_sympy x y
@syms_sympy x y :real => true :positive => true
Use syms_sympy(:x, :y; ...) for normal keyword syntax.
"""
macro syms_sympy(args...)
    vars = Symbol[]
    opts = Expr[]  # store `Expr(:kw, key, val)` later

    for a in args
        if a isa Symbol
            push!(vars, a)

        elseif a isa Expr && a.head == :call && a.args[1] == :(=>) && length(a.args) == 3
            key = a.args[2]
            val = a.args[3]

            # key can be Symbol (e.g., real) or QuoteNode(:real) depending on usage
            if key isa QuoteNode
                key = key.value
            end
            key isa Symbol || throw(ArgumentError("@syms option keys must be Symbols; got: $(key)"))

            push!(opts, Expr(:kw, key, val))

        else
            throw(ArgumentError("@syms expects Symbols and optional `key => value` pairs; got: $(a)"))
        end
    end

    assigns = Expr[]
    for v in vars
        name_str = String(v)
        if isempty(opts)
            push!(assigns, :( $(esc(v)) = syms_sympy($name_str) ))
        else
            kw = Expr(:parameters, opts...)
            push!(assigns, :( $(esc(v)) = syms_sympy($kw, $name_str) ))
        end
    end

    return Expr(:block, assigns...)
end
