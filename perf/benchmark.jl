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
bench(() -> L_show("A = ", A), "steady L_show matrix")

bench(() -> l_show("A = ", A), "first l_show matrix")
bench(() -> l_show("A = ", A), "steady l_show matrix")

bench(() -> L_show("x = ", lc([2, -1, 3], [A[:, 1], A[:, 2], b])), "linear combination")
bench(() -> L_show("x = ", lc([2, -1, 3], [A[:, 1], A[:, 2], b])), "steady lc")

bench(() -> begin
    set_backend!(:symbolics)
    x, y = syms(:x, :y)
    L_show((x + y)^2; symopts=(expand=true,))
end, "symbolics render")
bench(() -> begin
    set_backend!(:symbolics)
    x, y = syms(:x, :y)
    L_show((x + y)^2; symopts=(expand=true,))
end, "steady symbolics")

if LAlatex.Backend.backend_usable(LAlatex.Backend.SymPyBackend)
    bench(() -> begin
        set_backend!(:sympy)
        a = syms(:a; backend=:sympy, real=true)
        L_show(a^2 + 2a + 1)
    end, "sympy bootstrap")
    bench(() -> begin
        set_backend!(:sympy)
        a = syms(:a; backend=:sympy, real=true)
        L_show(a^2 + 2a + 1)
    end, "sympy steady render")
else
    println(rpad("sympy bootstrap", 24), "skipped (backend unusable)")
    println(rpad("sympy steady render", 24), "skipped (backend unusable)")
end
