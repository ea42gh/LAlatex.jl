using BlockArrays: BlockArray, BlockMatrix
using LaTeXStrings: LaTeXString
using LinearAlgebra: Adjoint, Diagonal, Transpose
using SparseArrays: SparseMatrixCSC
raw"""
    L_interp(template::LaTeXString, substitutions::Dict) -> LaTeXString

Interpolate values into a LaTeXString template using `$(key)` placeholders.
"""
function L_interp(template::LaTeXString, substitutions::Dict)
    str = String(template)
    for (key, value) in substitutions
        str = replace(str, "\$($key)" => string(value))
    end
    return LaTeXString(str)
end

"""
    apply_function(f, matrices) -> Vector

Apply a function elementwise to a list of lists of matrices, skipping `:none`/`nothing`.
"""
function apply_function(f, matrices)
    return [[is_none_val(mat) ? nothing : f.(mat) for mat in row] for row in matrices]
end

"""
    round_value(x, digits::Int=0)

Round a numeric value, returning `Int` when `digits == 0`.
"""
function round_value(x, digits::Int=0)
    v = round(x, digits=digits)
    return digits == 0 ? Int(v) : v
end

"""
    round_value(x::Complex, digits::Int=0) -> Complex

Round complex values elementwise.
"""
function round_value(x::Complex, digits::Int=0)
    return Complex(round_value(real(x), digits), round_value(imag(x), digits))
end

"""
    round_matrices(matrices; digits=0) -> Vector

Round each numeric entry in a list of lists of matrices.
"""
function round_matrices(matrices; digits=0)
    return apply_function(x -> round_value(x, digits), matrices)
end

"""
    round_matrices(matrices, digits::Int) -> Vector

Positional `digits` overload for rounding nested matrix collections.
"""
function round_matrices(matrices, digits::Int)
    return round_matrices(matrices; digits=digits)
end

"""
    print_np_array_def(A; nm="A") -> String

Return a NumPy array definition string for display or copy/paste.
"""
function print_np_array_def(A; nm="A")
    function format_element(x)
        if x isa Rational
            return string(numerator(x)) * "//" * string(denominator(x))
        elseif x isa Complex
            real_part = real(x)
            imag_part = imag(x)
            if imag_part < 0
                return string(format_element(real_part)) * " - " * string(abs(imag_part)) * "j"
            else
                return string(format_element(real_part)) * " + " * string(imag_part) * "j"
            end
        elseif x isa Real
            return string(x)
        elseif x isa Integer
            return string(x)
        else
            error("Unsupported type for printing as NumPy array: $(typeof(x))")
        end
    end
    if ndims(A) == 1
        return nm * " = np.array([" * join(format_element.(A), ", ") * "])"
    else
        M, N = size(A)
        rows = ["[" * join(format_element.(A[i, :]), ", ") * "]" for i in 1:M]
        return nm * " = np.array([\n" * join(rows, ",\n") * "\n])"
    end
end
"""
    factor_out_denominator(A) -> (factor, A_factored)

Return a common denominator factor and a scaled array for rational inputs.
"""
function factor_out_denominator(A)
    return 1, A
end

"""
    factor_out_denominator(A::AbstractArray) -> (factor, A_factored)

Factor out the least common denominator for rational entries in mixed arrays.
Symbols and non-rational numeric entries are scaled by the factor; unsupported
entries return the original array with factor 1.
"""
function factor_out_denominator(A::AbstractArray)
    denominators = Int[]
    collect_symbolics_denoms = function(x; include_integers=false)
        local function push_literal_denominator(val; include_integers_local=false)
            if val isa Rational
                push!(denominators, denominator(val))
            elseif include_integers_local && val isa Integer
                push!(denominators, Int(val))
            elseif val isa Complex{Rational{Int}}
                push!(denominators, denominator(real(val)))
                push!(denominators, denominator(imag(val)))
            end
        end
        local function walk(expr; include_integers_local=false)
            if expr isa Symbolics.Num
                return walk(Symbolics.unwrap(expr); include_integers_local=include_integers_local)
            end

            if Symbolics.SymbolicUtils.isadd(expr)
                for coeff in symbolic_term_coefficients(expr)
                    if coeff isa Symbolics.Num && Symbolics.SymbolicUtils.is_literal_number(coeff)
                        coeff = Symbolics.SymbolicUtils.unwrap_const(coeff)
                    end
                    push_literal_denominator(coeff; include_integers_local=include_integers_local)
                end
            end

            if Symbolics.SymbolicUtils.isdiv(expr)
                if hasfield(typeof(expr), :num) && hasfield(typeof(expr), :den)
                    walk(getfield(expr, :num); include_integers_local=false)
                    walk(getfield(expr, :den); include_integers_local=true)
                end
                return
            end

            if Symbolics.SymbolicUtils.is_literal_number(expr)
                val = Symbolics.SymbolicUtils.unwrap_const(expr)
                push_literal_denominator(val; include_integers_local=include_integers_local)
                return
            end

            if hasfield(typeof(expr), :coeff)
                coeff = getfield(expr, :coeff)
                if coeff isa Symbolics.Num && Symbolics.SymbolicUtils.is_literal_number(coeff)
                    coeff = Symbolics.SymbolicUtils.unwrap_const(coeff)
                end
                push_literal_denominator(coeff; include_integers_local=include_integers_local)
            end

            if hasfield(typeof(expr), :dict)
                dict = getfield(expr, :dict)
                try
                    for (k, v) in dict
                        walk(k; include_integers_local=include_integers_local)
                        walk(v; include_integers_local=include_integers_local)
                    end
                catch
                    # ignore non-iterable dict-like structures
                end
            end

            ok, rat = Symbolics.SymbolicUtils.ratcoeff(expr)
            if ok
                if rat isa Rational
                    push!(denominators, denominator(rat))
                elseif include_integers_local && rat isa Integer
                    push!(denominators, Int(rat))
                end
                return
            end

            if expr isa Rational{Int}
                push!(denominators, denominator(expr))
                return
            elseif include_integers_local && expr isa Integer
                push!(denominators, Int(expr))
                return
            elseif expr isa Complex{Rational{Int}}
                push!(denominators, denominator(real(expr)))
                push!(denominators, denominator(imag(expr)))
                return
            elseif expr isa Number
                return
            elseif Symbolics.SymbolicUtils.iscall(expr)
                op = Symbolics.SymbolicUtils.operation(expr)
                args = Symbolics.SymbolicUtils.arguments(expr)
                if op === (/) && length(args) >= 2
                    walk(args[1]; include_integers_local=false)
                    walk(args[2]; include_integers_local=true)
                    return
                end
                for arg in args
                    walk(arg; include_integers_local=include_integers_local)
                end
            end
        end
        walk(x; include_integers_local=include_integers)
    end
    for x in A
        if x isa Rational{Int}
            push!(denominators, denominator(x))
        elseif x isa Complex{Rational{Int}}
            push!(denominators, denominator(real(x)))
            push!(denominators, denominator(imag(x)))
        elseif x isa Complex
            xr = real(x)
            xi = imag(x)
            if xr isa Symbolics.Num
                collect_symbolics_denoms(xr)
            elseif _is_pythoncall_py(xr)
                den = try
                    sympy = import_sympy()
                    sympy.denom(xr)
                catch
                    nothing
                end
                if den !== nothing
                    pc = _ensure_pythoncall()
                    den_jl = try
                        pc.pyconvert(Any, den)
                    catch
                        nothing
                    end
                    if den_jl isa Integer
                        push!(denominators, Int(den_jl))
                    elseif den_jl isa Rational{Int}
                        push!(denominators, denominator(den_jl))
                    end
                end
            end
            if xi isa Symbolics.Num
                collect_symbolics_denoms(xi)
            elseif _is_pythoncall_py(xi)
                den = try
                    sympy = import_sympy()
                    sympy.denom(xi)
                catch
                    nothing
                end
                if den !== nothing
                    pc = _ensure_pythoncall()
                    den_jl = try
                        pc.pyconvert(Any, den)
                    catch
                        nothing
                    end
                    if den_jl isa Integer
                        push!(denominators, Int(den_jl))
                    elseif den_jl isa Rational{Int}
                        push!(denominators, denominator(den_jl))
                    end
                end
            end
        elseif x isa Symbolics.Num
            sf = try
                Symbolics.simplify_fractions(x)
            catch
                nothing
            end
            if sf !== nothing
                den_sf = try
                    Base.denominator(sf)
                catch
                    nothing
                end
                if den_sf isa Integer
                    push!(denominators, Int(den_sf))
                elseif den_sf isa Rational{Int}
                    push!(denominators, denominator(den_sf))
                elseif den_sf isa Symbolics.Num
                    if Symbolics.SymbolicUtils.is_literal_number(den_sf)
                        val = Symbolics.SymbolicUtils.unwrap_const(den_sf)
                        if val isa Integer
                            push!(denominators, Int(val))
                        elseif val isa Rational
                            push!(denominators, denominator(val))
                        end
                    else
                        collect_symbolics_denoms(den_sf; include_integers=true)
                    end
                elseif den_sf !== nothing
                    collect_symbolics_denoms(den_sf; include_integers=true)
                end
            end
            den = try
                Base.denominator(x)
            catch
                nothing
            end
            if den isa Integer
                push!(denominators, Int(den))
            elseif den isa Rational{Int}
                push!(denominators, denominator(den))
            elseif den isa Symbolics.Num
                if Symbolics.SymbolicUtils.is_literal_number(den)
                    val = Symbolics.SymbolicUtils.unwrap_const(den)
                    if val isa Integer
                        push!(denominators, Int(val))
                    elseif val isa Rational
                        push!(denominators, denominator(val))
                    end
                else
                    collect_symbolics_denoms(den; include_integers=true)
                end
            elseif den !== nothing
                collect_symbolics_denoms(den; include_integers=true)
            end
            expr = Symbolics.unwrap(x)
            dens = try
                Symbolics.SymbolicUtils.denominators(expr)
            catch
                Any[]
            end
            for d in dens
                collect_symbolics_denoms(d; include_integers=true)
            end
            collect_symbolics_denoms(x)
        elseif _is_pythoncall_py(x)
            den = try
                sympy = import_sympy()
                sympy.denom(x)
            catch
                nothing
            end
            if den !== nothing
                pc = _ensure_pythoncall()
                den_jl = try
                    pc.pyconvert(Any, den)
                catch
                    nothing
                end
                if den_jl isa Integer
                    push!(denominators, Int(den_jl))
                elseif den_jl isa Rational{Int}
                    push!(denominators, denominator(den_jl))
                end
            end
        elseif x isa Number || x isa Symbolics.Num
            # ok
        else
            return 1, A
        end
    end

    if isempty(denominators)
        return 1, A
    end

    d = reduce(lcm, denominators; init=1)
    d == 1 && return 1, A
    factored = map(x -> d * x, A)
    if any(x -> x isa Symbolics.Num || Symbolics.SymbolicUtils.issym(x) || Symbolics.SymbolicUtils.iscall(x), factored)
        factored = try
            Symbolics.expand.(factored)
        catch
            factored
        end
    elseif any(_is_pythoncall_py, factored)
        sympy = import_sympy()
        factored = map(x -> _is_pythoncall_py(x) ? sympy.expand(x) : x, factored)
    end
    return d, factored
end

"""
    factor_out_denominator(A::AbstractVector{Rational{Int}}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a rational vector.
"""
function factor_out_denominator(A::AbstractVector{Rational{Int}})
    d = reduce(lcm, denominator.(A))
    return d, Int64.(d .* A)
end

"""
    factor_out_denominator(A::AbstractMatrix{Rational{Int}}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a rational matrix.
"""
function factor_out_denominator(A::AbstractMatrix{Rational{Int}})
    d = reduce(lcm, denominator.(A))
    return d, Int64.(d .* A)
end

"""
    factor_out_denominator(A::AbstractVector{Complex{Rational{Int}}}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a complex rational vector.
"""
function factor_out_denominator(A::AbstractVector{Complex{Rational{Int}}})
    denominators_real = denominator.(real.(A))
    denominators_imag = denominator.(imag.(A))
    d = reduce(lcm, vcat(denominators_real, denominators_imag), init=1)
    A_int = Complex{Int64}.(d .* real.(A), d .* imag.(A))
    return d, A_int
end

"""
    factor_out_denominator(A::AbstractMatrix{Complex{Rational{Int}}}) -> (factor, A_factored)

Factor out the least common multiple of denominators for a complex rational matrix.
"""
function factor_out_denominator(A::AbstractMatrix{Complex{Rational{Int}}})
    denominators_real = denominator.(real.(A))
    denominators_imag = denominator.(imag.(A))
    d = reduce(lcm, vcat(denominators_real, denominators_imag), init=1)
    A_int = Complex{Int64}.(d .* real.(A), d .* imag.(A))
    return d, A_int
end

"""
    factor_out_denominator(A::Transpose) -> (factor, A_factored)

Preserve transposition while factoring denominators.
"""
function factor_out_denominator(A::Transpose)
    d, A_factored = factor_out_denominator(parent(A))
    return d, transpose(A_factored)
end

"""
    factor_out_denominator(A::BlockArray) -> (factor, A_factored)

Factor denominators in a BlockArray and reconstruct the block structure.
"""
function factor_out_denominator(A::BlockArray)
    full_matrix = copy(Matrix(A))
    d, A_factored = factor_out_denominator(full_matrix)
    return d, BlockArray(A_factored, axes(A))
end

"""
    factor_out_denominator(A::Adjoint) -> (factor, A_factored)

Preserve adjoint while factoring denominators.
"""
function factor_out_denominator(A::Adjoint)
    d, A_factored = factor_out_denominator(parent(A))
    return d, A_factored'
end

"""
    factor_out_denominator(A::Base.ReshapedArray) -> (factor, A_factored)

Factor denominators while preserving the original reshaped size.
"""
function factor_out_denominator(A::Base.ReshapedArray{T, 2, Adjoint{T, Vector{T}}, Tuple{}}) where T
    original_shape = size(A)
    d, A_factored = factor_out_denominator(parent(A))
    reshaped_A_factored = reshape(A_factored, original_shape)
    return d, reshaped_A_factored
end

"""
    style_wrapper(content; color_opt=nothing) -> String

Optionally wrap LaTeX content in a `\\textcolor{}` block.
"""
function style_wrapper(content::Any, color_opt=nothing)
    str_content = string(content)
    str_content = strip(str_content, ['$', '\n'])
    if color_opt !== nothing
        return "\\textcolor{$color_opt}{$str_content}"
    end
    return str_content
end

"""
    parse_arraystyle(arraystyle, is_block_array=false) -> (arraystyle, env, left, right)

Normalize an arraystyle and return the LaTeX environment and brackets.
"""
function parse_arraystyle(arraystyle, is_block_array=false)
    valid_styles = [:bmatrix, :Bmatrix, :pmatrix, :vmatrix, :Vmatrix, :array, :barray, :Barray, :parray, :varray, :Varray]
    if !(arraystyle in valid_styles)
        arraystyle = :array
    end

    if is_block_array
        arraystyle_map = Dict(
            :bmatrix => :barray,
            :Bmatrix => :Barray,
            :pmatrix => :parray,
            :vmatrix => :varray,
            :Vmatrix => :Varray,
            :array => :array
        )
        arraystyle = get(arraystyle_map, arraystyle, arraystyle)
    end

    env_map = Dict(
        :bmatrix => "bmatrix",
        :Bmatrix => "Bmatrix",
        :pmatrix => "pmatrix",
        :vmatrix => "vmatrix",
        :Vmatrix => "Vmatrix",
        :array => "array",
        :barray => "array",
        :Barray => "array",
        :parray => "array",
        :varray => "array",
        :Varray => "array"
    )
    matrix_env = get(env_map, arraystyle, "array")

    bracket_format = Dict(
        :barray => ("\\left[", "\\right]"),
        :Barray => ("\\left\\{", "\\right\\}"),
        :parray => ("\\left(", "\\right)"),
        :varray => ("\\left|", "\\right|"),
        :Varray => ("\\left\\|", "\\right\\|"),
        :array => ("", "")
    )
    left_bracket, right_bracket = get(bracket_format, arraystyle, ("", ""))
    return arraystyle, matrix_env, left_bracket, right_bracket
end

"""
    construct_col_format(num_cols, col_dividers; alignment="r") -> String

Construct a LaTeX column alignment string with optional dividers.
"""
function construct_col_format(num_cols, col_dividers, alignment="r")
    clean_dividers = filter(d -> d < num_cols, col_dividers)
    col_format = join(["$alignment" * (j in clean_dividers ? "|" : "") for j in 1:num_cols], "")
    return "{$col_format}"
end

"""
    process_array(A; factor_out=true) -> (factor, A_factored)

Apply denominator factorization for rational arrays when requested.
"""
function process_array(A, factor_out=true)
    if !factor_out
        return 1, A
    end
    return factor_out_denominator(A)
end

"""
    L_show_number(x; color=nothing, number_formatter=nothing) -> String

Render a number as LaTeX, with optional formatting and color.
"""
function L_show_number(x; color=nothing, number_formatter=nothing)
    formatted_x = number_formatter !== nothing ? number_formatter(x) : x
    formatted = to_latex(formatted_x)
    return style_wrapper(formatted, color)
end

"""
    L_show_string(s; color=nothing) -> String

Render a string or LaTeXString with optional color.
"""
function L_show_string(s; color=nothing)
    formatted = to_latex(s)
    return style_wrapper(formatted, color)
end

"""
    format_matrix_row(A, i, per_element_style, row_dividers) -> String

Format a single matrix row for LaTeX output.
"""
function format_matrix_row(A, i, per_element_style, row_dividers)
    row = join(
        [begin
            x = A[i, j]
            formatted_x = to_latex(x)
            per_element_style !== nothing ? per_element_style(x, i, j, formatted_x) : formatted_x
        end for j in 1:size(A, 2)], " & "
    )

    if i in row_dividers && i < size(A, 1)
        return row * " \\\\ \\hline"
    end
    return row * " \\\\"
end

"""
    construct_latex_matrix_body(A, arraystyle, is_block_array, per_element_style,
                                factor_out, number_formatter, is_transposed, is_hermitian) -> String

Construct a LaTeX matrix body with optional block dividers and formatting.
"""
function construct_latex_matrix_body(A, arraystyle, is_block_array, per_element_style,
                                     factor_out, number_formatter,
                                     is_transposed, is_hermitian)
    arraystyle, matrix_env, left_bracket, right_bracket = parse_arraystyle(arraystyle, is_block_array)

    row_dividers, col_dividers = Int[], Int[]
    if is_block_array
        row_blocks, col_blocks = axes(A)
        row_dividers = isempty(row_blocks.lasts) ? Int[] : collect(row_blocks.lasts[1:end-1])
        col_dividers = isempty(col_blocks.lasts) ? Int[] : collect(col_blocks.lasts[1:end-1])
        row_dividers = filter(d -> 1 <= d < size(A, 1), row_dividers)
        col_dividers = filter(d -> 1 <= d < size(A, 2), col_dividers)
    end

    col_format_str = matrix_env == "array" ? construct_col_format(size(A, 2), col_dividers) : ""

    if number_formatter !== nothing
        A = map(x -> number_formatter(x), A)
    end

    factor, intA = process_array(A, factor_out)

    matrix_rows = [format_matrix_row(intA, i, per_element_style, row_dividers) for i in 1:size(A, 1)]
    matrix_body = left_bracket * "\\begin{$matrix_env}$col_format_str\n" *
                  join(matrix_rows, "\n") * "\n\\end{$matrix_env}" * right_bracket

    one_over_factor_str = factor == 1 ? "" : to_latex(1//factor)
    return isempty(one_over_factor_str) ? matrix_body : "$one_over_factor_str $matrix_body"
end

"""
    L_show_matrix(A; arraystyle=:parray, is_block_array=false, color=nothing,
                  number_formatter=nothing, per_element_style=nothing, factor_out=true) -> String

Render a matrix-like object as LaTeX.
"""
function L_show_matrix(A; arraystyle=:parray, is_block_array=false, color=nothing,
                       number_formatter=nothing, per_element_style=nothing,
                       factor_out=true, symopts=NamedTuple())
    symopts = normalize_symopts(symopts)
    is_transposed = A isa Transpose{<:Any, <:AbstractMatrix} ||
                    A isa Transpose{<:Any, <:BlockArray} ||
                    A isa Transpose{<:Any, <:AbstractVector}
    is_hermitian = A isa Adjoint{<:Any, <:AbstractMatrix} ||
                   A isa Adjoint{<:Any, <:BlockArray} ||
                   A isa Adjoint{<:Any, <:AbstractVector}

    if A isa Transpose{<:Any, <:AbstractVector} || A isa Adjoint{<:Any, <:AbstractVector}
        A = reshape(A, 1, :)
    end

    if A isa SparseMatrixCSC
        A = Matrix(A)
    elseif A isa Transpose{<:Any, <:BlockArray} || A isa Adjoint{<:Any, <:BlockArray}
        is_block_array = true
    elseif A isa Diagonal
        A = Matrix(A)
    end

    if any(x -> x isa Symbolics.Num || _is_pythoncall_py(x), A)
        A = map(x -> symbolic_transform(x; symopts...), A)
    end

    latex_output = construct_latex_matrix_body(A, arraystyle, is_block_array, per_element_style,
                                               factor_out, number_formatter,
                                               is_transposed, is_hermitian)
    return style_wrapper(latex_output, color)
end

"""
    LinearCombination(s, X, options)

Container for linear-combination rendering in `L_show`.
"""
struct LinearCombination
    s
    X
    options::NamedTuple
end

"""
    lc(s, X; kwargs...) -> LinearCombination

Create a linear-combination group that `l_show` can render.
"""
function lc(s, X; kwargs...)
    if _is_pythoncall_py(s) || _is_pythoncall_py(X)
        pc = _ensure_pythoncall()
        if pc !== nothing
            if _is_pythoncall_py(s)
                try
                    s = Base.invokelatest(pc.pyconvert, Vector{Any}, s)
                catch
                    try
                        s = vec(Base.invokelatest(pc.pyconvert, Matrix{Any}, s))
                    catch
                        # fall through with original s
                    end
                end
            end
            if _is_pythoncall_py(X)
                try
                    X = Base.invokelatest(pc.pyconvert, Matrix{Any}, X)
                catch
                    # fall through with original X
                end
            end
        end
    end
    return LinearCombination(s, X, (; kwargs...))
end

"""
    Group(entries, options)

Container for grouped LaTeX rendering.
"""
struct Group
    entries::Tuple
    options::NamedTuple
end

"""
    set(entries...; kwargs...) -> Group

Create a grouped collection of entries for `L_show`.
"""
function set(entries...; kwargs...)
    return Group(entries, (; kwargs...))
end

"""
    L_show_core(obj; kwargs...) -> String

Render a single object into a LaTeX fragment without math delimiters.
"""
function L_show_core(obj; setstyle=:Barray, arraystyle=:parray, color=nothing, separator=", ",
                     number_formatter=nothing, per_element_style=nothing,
                     factor_out=true, symopts=NamedTuple())
    symopts = normalize_symopts(symopts)
    if obj isa Group
        return L_show_set(obj;
            setstyle=setstyle,
            arraystyle=arraystyle,
            color=color,
            separator=separator,
            number_formatter=number_formatter,
            per_element_style=per_element_style,
            symopts=symopts,
        )
    end

    if obj isa LinearCombination
        return L_show_lc(obj; setstyle=setstyle, arraystyle=arraystyle, color=color,
                         number_formatter=number_formatter, per_element_style=per_element_style,
                         factor_out=factor_out, symopts=symopts)
    end

    if obj isa Tuple && isempty(obj)
        _, _, left_delim, right_delim = parse_arraystyle(arraystyle)
        return style_wrapper("$(left_delim) $(right_delim)", color)
    end

    if obj isa NamedTuple
        formatting_keys = [:setstyle, :arraystyle, :color, :separator, :number_formatter, :per_element_style, :factor_out]
        formatting_options = Dict(k => v for (k, v) in pairs(obj) if k in formatting_keys)
        content_values = Tuple(v for (k, v) in pairs(obj) if !(k in formatting_keys))

        combined_options = merge(Dict(
            :setstyle => setstyle,
            :arraystyle => arraystyle, :color => color, :separator => separator,
            :number_formatter => number_formatter, :per_element_style => per_element_style,
            :factor_out => factor_out
        ), formatting_options)

        combined_options[:symopts] = symopts
        formatted_entries = [L_show_core(entry; combined_options...) for entry in content_values]
        separator_str = normalize_separator(combined_options[:separator])
        return join(formatted_entries, separator_str)
    end

    if obj isa Tuple
        formatted_entries = [L_show_core(entry;
            setstyle=setstyle,
            arraystyle=arraystyle,
            color=color,
            separator=separator,
            number_formatter=number_formatter,
            per_element_style=per_element_style,
            factor_out=factor_out,
            symopts=symopts,
        ) for entry in obj]
        separator_str = normalize_separator(separator)
        return join(formatted_entries, separator_str)
    end

    if obj isa AbstractString
        return L_show_string(obj; color=color)
    end

    if obj isa Char
        return L_show_string(string(obj); color=color)
    end

    if obj isa Transpose{<:Any, <:String} || obj isa Adjoint{<:Any, <:String} ||
       obj isa Transpose{<:Any, <:Char} || obj isa Adjoint{<:Any, <:Char} ||
       obj isa Transpose{<:Any, <:LaTeXString} || obj isa Adjoint{<:Any, <:LaTeXString}
        return L_show_string(parent(obj); color=color)
    end

    if obj isa AbstractVector || obj isa Transpose{<:Any, <:AbstractVector} || obj isa Adjoint{<:Any, <:AbstractVector} ||
       obj isa AbstractMatrix || obj isa Transpose{<:Any, <:AbstractMatrix} || obj isa Adjoint{<:Any, <:AbstractMatrix} ||
       obj isa BlockMatrix || obj isa Transpose{<:Any, <:BlockMatrix} || obj isa Adjoint{<:Any, <:BlockMatrix} ||
       obj isa BlockArray || obj isa Transpose{<:Any, <:BlockArray} || obj isa Adjoint{<:Any, <:BlockArray}
        is_block_array = obj isa BlockArray || obj isa Transpose{<:BlockArray} || obj isa Adjoint{<:BlockArray} ||
                         obj isa BlockMatrix || obj isa Transpose{<:BlockMatrix} || obj isa Adjoint{<:BlockMatrix}
        return L_show_matrix(obj; arraystyle=arraystyle, is_block_array=is_block_array,
                             color=color, number_formatter=number_formatter,
                             per_element_style=per_element_style, factor_out=factor_out,
                             symopts=symopts)
    end

    if obj isa Symbol || obj isa Symbolics.Num
        return style_wrapper(to_latex(symbolic_transform(obj; symopts...)) * " ", color)
    elseif _is_sympy_py(obj)
        pc = _pythoncall_module()
        if pc !== nothing
            # Prefer rendering SymPy matrices via L_show_matrix so arraystyle applies.
            try
                tolist = Base.invokelatest(pc.pygetattr, obj, "tolist")
                shape = Base.invokelatest(pc.pygetattr, obj, "shape")
                shp = Base.invokelatest(pc.pyconvert, Tuple, shape)
                if length(shp) == 2
                    pyrows = Base.invokelatest(pc.pycall, tolist)
                    rows = Base.invokelatest(pc.pyconvert, Vector, pyrows)
                    m = length(rows)
                    n = m == 0 ? 0 : length(Base.invokelatest(pc.pyconvert, Vector, rows[1]))
                    A = Matrix{Any}(undef, m, n)
                    for i in 1:m
                        row = Base.invokelatest(pc.pyconvert, Vector, rows[i])
                        for j in 1:n
                            A[i, j] = row[j]
                        end
                    end
                    return L_show_matrix(A; arraystyle=arraystyle, color=color,
                                         number_formatter=number_formatter,
                                         per_element_style=per_element_style,
                                         factor_out=factor_out, symopts=symopts)
                end
            catch
                # Fallback to sympy.latex below.
            end
        end
        sympy = import_sympy()
        latex_py = sympy.latex(obj)
        latex_str = pc === nothing ? string(latex_py) : String(Base.invokelatest(pc.pyconvert, String, latex_py))
        return style_wrapper(latex_str, color)
    elseif obj isa Number || _is_pythoncall_py(obj)
        return L_show_number(symbolic_transform(obj; symopts...); color=color, number_formatter=number_formatter)
    end

    error("Unsupported argument type: $(typeof(obj))")
end

"""
    L_show_set(obj_group; kwargs...) -> String

Render a `Group` with delimiters and separators.
"""
function L_show_set(obj_group; setstyle=:Barray, arraystyle=:parray, color=nothing, separator=", ",
                    number_formatter=nothing, per_element_style=nothing, symopts=NamedTuple())
    symopts = normalize_symopts(symopts)
    if !(obj_group isa Group)
        error("L_show_set expected a Group, got: $(typeof(obj_group))")
    end

    formatting_keys = [:setstyle, :arraystyle, :color, :separator, :number_formatter, :per_element_style]
    group_options = Dict(k => v for (k, v) in pairs(obj_group.options) if k in formatting_keys)
    combined_options = merge(Dict(
        :setstyle => setstyle,
        :arraystyle => arraystyle,
        :color => color,
        :separator => separator,
        :number_formatter => number_formatter,
        :per_element_style => per_element_style,
        :symopts => symopts,
    ), group_options)

    clean_separator = normalize_separator(combined_options[:separator])
    _, _, left_delim, right_delim = parse_arraystyle(combined_options[:setstyle])

    obj_latex = map(obj -> L_show_core(obj;
                                       arraystyle=combined_options[:arraystyle],
                                       color=combined_options[:color],
                                       separator=combined_options[:separator],
                                       number_formatter=combined_options[:number_formatter],
                                       per_element_style=combined_options[:per_element_style],
                                       factor_out=true,
                                       symopts=combined_options[:symopts]),
                    obj_group.entries)

    joined_latex = obj_latex[1]
    for i in 2:length(obj_latex)
        joined_latex *= " " * clean_separator * " " * obj_latex[i]
    end

    formatted_group = LaTeXString("$(left_delim) " * joined_latex * " $(right_delim)")
    return style_wrapper(formatted_group, combined_options[:color])
end

"""
    L_show_lc(lcobj; kwargs...) -> String

Render a LinearCombination group.
"""
function L_show_lc(lcobj::LinearCombination; setstyle=:parray, arraystyle=:parray, color=nothing,
                   number_formatter=nothing, per_element_style=nothing,
                   factor_out=true, symopts=NamedTuple())
    symopts = normalize_symopts(symopts)
    local s = lcobj.s
    local X = lcobj.X

    opts = merge(Dict(
        :sign_policy=>:signed, :plus=>L" + ", :pos=>L" + ", :neg=>L" - ",
        :parens_coeff=>true, :omit_one=>true, :drop_zero=>true),
        Dict(pairs(lcobj.options))
    )

    inner = x -> L_show_core(x;
        arraystyle=arraystyle, color=color,
        number_formatter=number_formatter, per_element_style=per_element_style,
        factor_out=factor_out, symopts=symopts)

    needs_parens = x -> begin
        t = replace(inner(x), r"\s" => "")
        if isempty(t)
            return false
        end
        i = nextind(t, firstindex(t))
        while i <= lastindex(t)
            c = t[i]
            if c == '+' || c == '-'
                return true
            end
            i = nextind(t, i)
        end
        return false
    end

    n = X isa AbstractMatrix ? size(X, 2) : length(X)
    getvec(i) = X isa AbstractMatrix ? X[:, i] : X[i]

    if opts[:sign_policy] === :plus
        terms = map(1:n) do i
            c = strip(inner(s[i]))
            if opts[:drop_zero] && c == "0"
                return nothing
            end
            c = (opts[:omit_one] && c == "1") ? "" :
                (opts[:parens_coeff] && needs_parens(s[i])) ? "\\left(" * c * "\\right)" : c
            v = inner(getvec(i))
            (a = LaTeXString(c), b = LaTeXString(v), separator = "")
        end |> x -> filter(!isnothing, x)

        if isempty(terms)
            return L_show_number(0; color=color, number_formatter=number_formatter)
        end

        g = Group((terms...,), (; setstyle=:array))
        return L_show_set(g;
            setstyle=:array, arraystyle=arraystyle, color=color,
            number_formatter=number_formatter, per_element_style=per_element_style,
            separator = opts[:plus])
    end

    split_sign = function(raw0::AbstractString)
        r = String(strip(raw0))
        if occursin(r"^-\\s*\\((.*)\\)$", r)
            m = match(r"^-\\s*\\((.*)\\)$", r)
            return (true, String(m.captures[1]), true)
        end
        if startswith(r, "-")
            absraw = String(strip(r[2:end]))
            single = !(occursin(r"\\+", absraw) || occursin(r"(?<!^)-", absraw))
            return (true, absraw, single)
        end
        return (false, r, false)
    end

    pieces = Any[]
    for i in 1:n
        raw = String(strip(inner(s[i])))
        if opts[:drop_zero] && raw == "0"
            continue
        end
        isneg, absraw, factorizable = split_sign(raw)
        base = factorizable ? absraw : raw

        showtxt =
            (opts[:omit_one] && base == "1") ? "" :
            (opts[:parens_coeff] && needs_parens(factorizable ? absraw : raw)) ?
                "\\left(" * base * "\\right)" :
                base

        term = (a = LaTeXString(showtxt),
                b = LaTeXString(inner(getvec(i))),
                separator = "")

        if isempty(pieces)
            if isneg && factorizable
                push!(pieces, opts[:neg])
            end
            push!(pieces, term)
        else
            push!(pieces, (isneg && factorizable) ? opts[:neg] : opts[:pos])
            push!(pieces, term)
        end
    end

    if isempty(pieces)
        return L_show_number(0; color=color, number_formatter=number_formatter)
    end

    g = Group((pieces...,), (; setstyle=:array))
    return L_show_set(g;
        setstyle=:array, arraystyle=arraystyle, color=color,
        number_formatter=number_formatter, per_element_style=per_element_style,
        separator = L"")
end

"""
    L_show(objs...; inline=true, kwargs...) -> String

Render objects into a LaTeX string with optional inline delimiters.
"""
function L_show(objs...; setstyle=:parray, arraystyle=:parray, separator=", ", color=nothing,
                number_formatter=nothing, per_element_style=nothing, factor_out=true, inline=true,
                symopts=NamedTuple())
    symopts = normalize_symopts(symopts)
    formatted_objs = [
        L_show_core(obj; arraystyle=arraystyle, separator=separator, color=color,
                    number_formatter=number_formatter, per_element_style=per_element_style,
                    factor_out=factor_out, symopts=symopts)
        for obj in objs
    ]

    styled_content = join(formatted_objs, " ")
    return inline ? "\$" * styled_content * "\$\n" : "\\[" * styled_content * "\\]\n"
end

"""
    L_show(objs::SubString{String}; kwargs...) -> String

Allow SubString inputs in L_show.
"""
L_show(objs::SubString{String}; kwargs...) = L_show(String(objs); kwargs...)

"""
    L_show_core(obj::SubString{String}; kwargs...) -> String

Allow SubString inputs in L_show_core.
"""
L_show_core(obj::SubString{String}; kwargs...) = L_show_core(String(obj); kwargs...)

"""
    l_show(args...; kwargs...) -> LaTeXString

Return a LaTeXString for display in notebook environments.
"""
function l_show(args...; kwargs...)
    return LaTeXString(L_show(args...; kwargs...))
end
