using LAlatex
using LinearAlgebra
using Printf

function bench(f, label)
    elapsed = @elapsed result = f()
    println(rpad(label, 24), @sprintf("%.6f s", elapsed))
    return result
end

A = [1 2 3; 4 5 6]
b = [7, 8, 9]

println("LAlatex benchmark")
println("-----------------")

bench(() -> L_show("A = ", A), "first L_show matrix")
bench(() -> l_show("A = ", A), "first l_show matrix")

bench(() -> L_show("x = ", lc([2, -1, 3], [A[:, 1], A[:, 2], b])), "linear combination")

bench(() -> begin
    set_backend!(:symbolics)
    x, y = syms(:x, :y)
    L_show((x + y)^2; symopts=(expand=true,))
end, "symbolics render")

if LAlatex.Backend.backend_usable(LAlatex.Backend.SymPyBackend)
    bench(() -> begin
        set_backend!(:sympy)
        a = syms(:a; backend=:sympy, real=true)
        L_show(a^2 + 2a + 1)
    end, "sympy first render")
else
    println(rpad("sympy first render", 24), "skipped (backend unusable)")
end
