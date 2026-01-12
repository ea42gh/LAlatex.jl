"""
    mixed_matrix(rows::Tuple...) -> Matrix{Any}

Build a matrix from row tuples without triggering type promotion across backends.

Examples:
    mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
"""
function mixed_matrix(rows::Tuple...)
    nrows = length(rows)
    if nrows == 0
        return Matrix{Any}(undef, 0, 0)
    end
    ncols = length(rows[1])
    for row in rows
        length(row) == ncols || throw(ArgumentError("All rows must have the same length"))
    end
    A = Matrix{Any}(undef, nrows, ncols)
    for i in 1:nrows
        for j in 1:ncols
            A[i, j] = rows[i][j]
        end
    end
    return A
end

"""
    mixed_matrix(A::AbstractMatrix) -> Matrix{Any}

Convert an existing matrix to `Matrix{Any}` to avoid backend promotion issues.
"""
function mixed_matrix(A::AbstractMatrix)
    return Matrix{Any}(A)
end

"""
    @mixed_matrix [a b; c d]

Construct a `Matrix{Any}` from a matrix literal without triggering type promotion.
"""
macro mixed_matrix(expr)
    rows = LAlatex._mixed_matrix_rows(expr)
    return esc(:(mixed_matrix($(rows...))))
end

"""
    _mixed_matrix_rows(expr) -> Vector{Expr}

Internal helper to parse matrix literals into tuple rows.
"""
function _mixed_matrix_rows(expr)
    if expr isa Expr && expr.head == :vcat
        return [_mixed_matrix_row(row) for row in expr.args]
    elseif expr isa Expr && expr.head == :hcat
        return [_mixed_matrix_row(expr)]
    elseif expr isa Expr && expr.head == :vect
        return [:(($(arg),)) for arg in expr.args]
    end
    throw(ArgumentError("@mixed_matrix expects a matrix literal like [a b; c d]"))
end

"""
    _mixed_matrix_row(expr) -> Expr

Wrap a row expression into a tuple for `mixed_matrix`.
"""
function _mixed_matrix_row(expr)
    if expr isa Expr && expr.head == :row
        return :($(Expr(:tuple, expr.args...)))
    end
    if expr isa Expr && expr.head == :hcat
        return :($(Expr(:tuple, expr.args...)))
    end
    return :(($expr,))
end
