using Test
using LaTeXStrings

using BlockArrays
using LAlatex
using Symbolics

"""
Return (ok, sympy, exe) where `ok` is true if SymPy is importable via PythonCall.
`exe` is the Python executable reported by PythonCall when available.
"""
function _sympy_available()
    try
        exe = try
            LAlatex._python_exe_hint()
        catch
            nothing
        end
        sympy = LAlatex.import_sympy()
        return true, sympy, exe
    catch
        return false, nothing, nothing
    end
end

ok, sympy, pyexe = _sympy_available()
if pyexe !== nothing
    @info "PythonCall executable for tests" pyexe
end

@testset "LAlatex" begin
    LAlatex.set_backend!(:symbolics)
    @testset "Public exports" begin
        exported = names(LAlatex)
        expected_exports = [
            Symbol("@syms"), Symbol("@syms_sympy"), Symbol("@mixed_matrix"),
            :syms, :syms_sympy, :import_sympy, :get_backend, :set_backend!,
            :symbolic_transform, :symbolic_term_coefficients,
            :to_latex, :L_show, :l_show, :L_interp, :to_html,
            :mixed_matrix, :set, :lc, :cases, :aligned, :factor_out_denominator,
            :bold_formatter, :scientific_formatter, :tril_formatter,
        ]
        @test all(name -> name in exported, expected_exports)
        @test :syms_symbolics ∉ exported
        @test :assume_symbolics! ∉ exported
        @test :symbolics_assumptions ∉ exported
    end

    @testset "Symbolics default" begin
        LAlatex.set_backend!(:symbolics)
        @test LAlatex.get_backend() isa LAlatex.Backend.SymbolicsBackend
        @test LAlatex.Backend.backend_available(LAlatex.Backend.SymbolicsBackend)

        x = LAlatex.syms(:x)
        @test x isa Symbolics.Num
        @test string(x) == "x"

        y = LAlatex.syms("y")
        @test y isa Symbolics.Num
        @test string(y) == "y"

        a, b = LAlatex.syms(:a, :b)
        @test a isa Symbolics.Num
        @test b isa Symbolics.Num

        LAlatex.@syms u v
        @test u isa Symbolics.Num
        @test v isa Symbolics.Num

        xr = LAlatex.syms(:xr; real=true, positive=true)
        @test LAlatex.assumptions(xr)[:real] == true
        @test LAlatex.assumptions(xr)[:positive] == true

        LAlatex.@syms q :real => true
        @test LAlatex.assumptions(q)[:real] == true
    end

    if ok
        @testset "SymPy integration" begin
            LAlatex.set_backend!(:sympy)
            @test LAlatex.Backend.backend_available(LAlatex.Backend.SymPyBackend)
            xs = LAlatex.syms_sympy(:x)
            ys = LAlatex.syms_sympy(:y; real=true, positive=true)
            @test string(xs) == "x"
            @test string(ys) == "y"
            m, n = LAlatex.syms_sympy(:m, :n)
            @test string(m) == "m"
            @test string(n) == "n"
            @test string(LAlatex.syms(:u)) == "u"

            LAlatex.@syms_sympy p :real => true :positive => true
            @test string(p) == "p"
            @test Bool(sympy.ask(sympy.Q.real(p)))
            @test Bool(sympy.ask(sympy.Q.positive(p)))

            LAlatex.set_backend!(LAlatex.Backend.SymPyBackend())
            LAlatex.@syms s :real => true
            @test string(s) == "s"
            @test Bool(sympy.ask(sympy.Q.real(s)))

            LAlatex.set_backend!(:symbolics)
            LAlatex.@syms t
            @test t isa Symbolics.Num
        end
    else
        @info "SymPy not available in the current PythonCall environment; skipping SymPy integration tests."
    end

    @testset "HTML helpers" begin
        LAlatex.set_backend!(:symbolics)
        html = LAlatex.to_html("hello"; sz=18, color="blue", justify="center", height=20, width=80, env="em")
        @test occursin("hello", html)
        @test occursin("font-size: 18px", html)
        @test occursin("color: blue", html)
        escaped_html = LAlatex.to_html("<script>"; env="script onclick=1")
        @test occursin("&lt;script&gt;", escaped_html)
        @test !occursin("<script>", escaped_html)
        @test occursin("<strong>", escaped_html)

        html2 = LAlatex.to_html("a", "b"; sz1=10, sz2=12, color="black", justify="left")
        @test occursin(">a<", html2)
        @test occursin(">b<", html2)

        out = LAlatex.show_html("hi")
        @test out isa LAlatex.HTMLOut
        @test occursin("hi", out.html)

        out2 = LAlatex.pr("para")
        @test out2 isa LAlatex.HTMLOut
        @test occursin("para", out2.html)

        captured = LAlatex.capture_output(() -> println("line1"))
        @test occursin("line1", captured)

        side = LAlatex.show_side_by_side_html(["one", "two"], ["A", "B"])
        @test occursin("one", side)
        @test occursin("two", side)
        @test occursin("A", side)
        @test occursin("B", side)
        escaped_side = LAlatex.show_side_by_side_html(["<b>x</b>"], ["<i>t</i>"])
        @test occursin("&lt;b&gt;x&lt;/b&gt;", escaped_side)
        @test occursin("&lt;i&gt;t&lt;/i&gt;", escaped_side)

        side_obj = LAlatex.show_side_by_side(["x", "y"])
        @test side_obj isa LAlatex.SideBySideHTML
        @test occursin("x", side_obj.html)
        @test occursin("y", side_obj.html)

        io = IOBuffer()
        show(io, MIME("text/html"), out)
        @test occursin("hi", String(take!(io)))

        io = IOBuffer()
        show(io, MIME("text/html"), side_obj)
        @test occursin("x", String(take!(io)))
    end

    @testset "LaTeX helpers" begin
        LAlatex.set_backend!(:symbolics)
        @test LAlatex.to_latex("a_b") == "\\text{a\\_b}"
        @test LAlatex.to_latex("50% & # {x} \\") == "\\text{50\\% \\& \\# \\{x\\} \\textbackslash{}}"
        @test LAlatex.to_latex("x~y^z") == "\\text{x\\textasciitilde{}y\\textasciicircum{}z}"
        @test LAlatex.to_latex("= 0") == "= 0"
        @test LAlatex.to_latex(LaTeXString("\\alpha + 1")) == "\\alpha + 1"
        @test LAlatex.to_latex('x') == "\\text{x}"
        @test LAlatex.to_latex(3//4) == "\\frac{3}{4}"
        @test LAlatex.to_latex(2 + 0im) == "2"
        @test LAlatex.to_latex(0 + 1im) == "\\mathit{i}"
        @test LAlatex.to_latex(0 + -1im) == "-\\mathit{i}"
        @test LAlatex.to_latex(:alpha) == "alpha"
        @test LAlatex.to_latex([1, 2, 3]) == ["1", "2", "3"]
        @test LAlatex.to_latex([1 2; 3 4]) == ["1" "2"; "3" "4"]
        @test LAlatex.to_latex([[[1 2]], [[3 4]]]) == [[["1" "2"]], [["3" "4"]]]

        LAlatex.@syms z
        latex_z = LAlatex.to_latex(z)
        @test occursin("z", latex_z)

        block_vector_latex = LAlatex.to_latex(BlockArray([1//2, 1//3, 1//4], [1, 2]))
        @test block_vector_latex == ["\\frac{1}{2}", "\\frac{1}{3}", "\\frac{1}{4}"]

        if ok
            sp = LAlatex.syms(:sp; backend=:sympy, real=true)
            latex_sp = LAlatex.to_latex(sp)
            @test occursin("sp", latex_sp)
        end

    end

    @testset "Symbolic display policy" begin
        LAlatex.set_backend!(:symbolics)
        @variables x y t n

        @testset "Backend parity checklist" begin
            sx, sy = x, y
            symbolics_scalar = LAlatex.to_latex(sx + sy)
            symbolics_matrix = LAlatex.L_show([sx sy; sy sx])
            @test occursin("x", symbolics_scalar)
            @test occursin("y", symbolics_scalar)
            @test LAlatex._to_latex_matrix_entry(sx) == LAlatex.to_latex(sx)
            @test occursin("x", symbolics_matrix)
            @test occursin("y", symbolics_matrix)

            symbolics_expanded = LAlatex.L_show((sx + sy)^2; symopts=(expand=true,))
            @test occursin("x", symbolics_expanded)
            @test occursin("y", symbolics_expanded)

            symbolics_factor, symbolics_factored = LAlatex.factor_out_denominator([sx / 2 sx])
            @test symbolics_factor == 2
            @test isequal(symbolics_factored[1, 1], sx)
            @test isequal(symbolics_factored[1, 2], 2sx)

            symbolics_lc = LAlatex.L_show(LAlatex.lc([-(sx + sy), sx - sy], [sx sy]))
            @test occursin("-  \\left", symbolics_lc)
            @test occursin("+  \\left(-", symbolics_lc)

            if ok
                LAlatex.set_backend!(:sympy)
                sympy = LAlatex.import_sympy()
                px, py = LAlatex.syms(:px, :py)
                sympy_scalar = LAlatex.to_latex(px + py)
                sympy_matrix = LAlatex.L_show([px py; py px])
                @test occursin("px", sympy_scalar)
                @test occursin("py", sympy_scalar)
                @test LAlatex._to_latex_matrix_entry(px) == LAlatex.to_latex(px)
                @test occursin("px", sympy_matrix)
                @test occursin("py", sympy_matrix)

                sympy_expanded = LAlatex.L_show((px + py)^2; symopts=(expand=true,))
                @test occursin("px", sympy_expanded)
                @test occursin("py", sympy_expanded)

                sympy_factor, sympy_factored = LAlatex.factor_out_denominator([px / 2 px])
                @test sympy_factor == 2
                @test LAlatex.to_latex(sympy_factored[1, 1]) == LAlatex.to_latex(px)
                @test LAlatex.to_latex(sympy_factored[1, 2]) == LAlatex.to_latex(2 * px)

                sympy_power = sympy.Rational(3, 10)^px
                sympy_power_factor, _ = LAlatex.factor_out_denominator([sympy_power px])
                @test sympy_power_factor == 1

                sympy_lc = LAlatex.L_show(LAlatex.lc([-(px + py), px - py], [px py]))
                @test occursin("-  \\left", sympy_lc)
                @test occursin("+  \\left", sympy_lc)
                LAlatex.set_backend!(:symbolics)
            end
        end

        alpha = LAlatex.syms("α_1")
        latex_alpha = LAlatex.to_latex(alpha)
        @test occursin("\\alpha", latex_alpha) || occursin("α", latex_alpha)
        @test occursin("_1", latex_alpha)

        pi_over_3 = Num(π) / 3
        latex_pi_over_3 = LAlatex.to_latex(pi_over_3)
        @test occursin("\\pi", latex_pi_over_3)
        @test occursin("3", latex_pi_over_3)
        @test !occursin("1.047", latex_pi_over_3)

        latex_cos = LAlatex.to_latex(cos(pi_over_3))
        @test occursin("\\cos\\left(", latex_cos)
        @test occursin("\\pi", latex_cos)
        @test occursin("3", latex_cos)

        latex_sin = LAlatex.to_latex(sin(pi_over_3))
        @test occursin("\\sin\\left(", latex_sin)
        @test occursin("\\pi", latex_sin)
        @test occursin("3", latex_sin)

        latex_exp = LAlatex.to_latex(exp(-3t))
        @test occursin("e^{", latex_exp)
        @test !occursin("\\begin{equation}", latex_exp)
        exp_vec = Num[(6//1) - (5//1)*exp(-3t), (18//1) - (19//1)*exp(-3t), (18//1) - (16//1)*exp(-3t)]
        exp_vec_latex = LAlatex.L_show(exp_vec)
        @test occursin("e^{", exp_vec_latex)
        @test !occursin("\\begin{equation}", exp_vec_latex)
        @test exp_vec_latex == "\$\\left(\\begin{array}{r}\n6 - 5 e^{-3 t} \\\\\n18 - 19 e^{-3 t} \\\\\n18 - 16 e^{-3 t} \\\\\n\\end{array}\\right)\$\n"

        matrix_latex = LAlatex.L_show([x y; y x])
        @test occursin("x", matrix_latex)
        @test occursin("y", matrix_latex)
        @test !occursin(" &  &", matrix_latex)
        @test LAlatex._to_latex_scalar(x) == LAlatex.to_latex(x)
        @test LAlatex._to_latex_matrix_entry(x) == LAlatex.to_latex(x)

        rational_power = LAlatex.L_show((3//10)^n)
        @test occursin("\\left(\\frac{3}{10}\\right)^{n}", rational_power)
        @test rational_power == "\$\\left(\\frac{3}{10}\\right)^{n} \$\n"

        for (f, latex_name) in (
            (log, "\\log"),
            (asin, "\\arcsin"),
            (acos, "\\arccos"),
            (atan, "\\arctan"),
            (sinh, "\\sinh"),
            (cosh, "\\cosh"),
            (tanh, "\\tanh"),
            (asinh, "\\operatorname{asinh}"),
            (acosh, "\\operatorname{acosh}"),
            (atanh, "\\operatorname{atanh}"),
        )
            rendered = LAlatex.to_latex(f(t))
            @test occursin(latex_name * "\\left(", rendered)
            @test !occursin("\\begin{equation}", rendered)
        end

        expr = (x + y)^2
        expanded = LAlatex.L_show(expr; symopts=(expand=true,))
        @test occursin("x^2", expanded) || occursin("x^{2}", expanded)

        complex_expr = (x + y)^2 + im * ((x + y)^2)
        complex_expanded = LAlatex.L_show(complex_expr; symopts=(expand=true,))
        @test !occursin("\\left(y + x\\right)^{2}", complex_expanded)
        @test occursin("x^{2}", complex_expanded) || occursin("x^2", complex_expanded)

        complex_matrix_expanded = LAlatex.L_show(LAlatex.mixed_matrix((complex_expr,)); symopts=(expand=true,))
        @test !occursin("\\left(y + x\\right)^{2}", complex_matrix_expanded)
        @test occursin("x^{2}", complex_matrix_expanded) || occursin("x^2", complex_matrix_expanded)

        @test LAlatex.to_latex(-x) == "-x"
        @test !occursin("-1", LAlatex.to_latex(-(x + y)))
        lc_signed = LAlatex.L_show(LAlatex.lc([-(x + y), x - y, 1], [x y x + y]))
        @test occursin("-  \\left", lc_signed)
        @test occursin("+  \\left(-", lc_signed)
        @test !occursin("\\left(1 ", lc_signed)
        @test !occursin(" -  \\left(1 ", lc_signed)
        @test lc_signed == "\$ -  \\left(y + x\\right)\\left(\\begin{array}{r}\nx \\\\\n\\end{array}\\right)  +  \\left(-y + x\\right)\\left(\\begin{array}{r}\ny \\\\\n\\end{array}\\right)  +  \\left(\\begin{array}{r}\ny + x \\\\\n\\end{array}\\right) \$\n"

        symA = [1//2 x; 3//4 y]
        factor, symA_out = LAlatex.factor_out_denominator(symA)
        @test factor == 4
        @test symA_out[1, 1] == 2
        @test isequal(symA_out[1, 2], 4 * x)
        @test symA_out[2, 1] == 3
        @test isequal(symA_out[2, 2], 4 * y)

        symB = LAlatex.mixed_matrix((1//2, x), ((1 + im)//3, y))
        factorB, symB_out = LAlatex.factor_out_denominator(symB)
        @test factorB == 6
        @test symB_out[1, 1] == 3
        @test isequal(symB_out[1, 2], 6 * x)
        @test symB_out[2, 1] == 2 + 2im
        @test isequal(symB_out[2, 2], 6 * y)

        symC = LAlatex.mixed_matrix((x / 2, 1//3), (x, y))
        factorC, symC_out = LAlatex.factor_out_denominator(symC)
        @test factorC == 6
        @test isequal(symC_out[1, 1], 3 * x)
        @test symC_out[1, 2] == 2

        complex_symbolic_matrix = LAlatex.mixed_matrix((x / 2 + im * (y / 3), 1//5), (x, y))
        factor_complex_symbolic, out_complex_symbolic = LAlatex.factor_out_denominator(complex_symbolic_matrix)
        @test factor_complex_symbolic == 30
        complex_symbolic_latex = LAlatex.L_show(out_complex_symbolic)
        @test !occursin("\\begin{equation}", complex_symbolic_latex)
        @test occursin("15 x", complex_symbolic_latex)
        @test occursin("10 y", complex_symbolic_latex)
        @test occursin("\\mathit{i}", complex_symbolic_latex)

        empty_rational_vector = Rational{Int}[]
        factor_empty_vector, out_empty_vector = LAlatex.factor_out_denominator(empty_rational_vector)
        @test factor_empty_vector == 1
        @test out_empty_vector === empty_rational_vector

        empty_rational_matrix = Matrix{Rational{Int}}(undef, 0, 2)
        factor_empty_matrix, out_empty_matrix = LAlatex.factor_out_denominator(empty_rational_matrix)
        @test factor_empty_matrix == 1
        @test out_empty_matrix === empty_rational_matrix
        @test size(out_empty_matrix) == (0, 2)

        big_rational_vector = [big(1)//big(2), big(2)//big(3)]
        factor_big_vector, out_big_vector = LAlatex.factor_out_denominator(big_rational_vector)
        @test factor_big_vector == big(6)
        @test out_big_vector == BigInt[3, 4]

        big_rational_matrix = [big(1)//big(2) big(1)//big(5); big(2)//big(3) big(3)//big(4)]
        factor_big_matrix, out_big_matrix = LAlatex.factor_out_denominator(big_rational_matrix)
        @test factor_big_matrix == big(60)
        @test out_big_matrix == BigInt[30 12; 40 45]

        big_complex_vector = Complex{Rational{BigInt}}[big(1)//big(2) + im * (big(1)//big(3))]
        factor_big_complex, out_big_complex = LAlatex.factor_out_denominator(big_complex_vector)
        @test factor_big_complex == big(6)
        @test out_big_complex == Complex{BigInt}[3 + 2im]

        @test sort(LAlatex._symbolics_denominators(x / 2 + 1//3)) == [2, 3]
        @test LAlatex._symbolics_denominators((x + 1) / 2) == [2]
        @test isempty(LAlatex._symbolics_denominators(x / (2y)))
        @test isempty(LAlatex._symbolics_denominators((x / 2)^n))

        p = (3//10)^n
        @test isempty(LAlatex._symbolics_denominators(p))
        power_matrix = [-6p p p; -21p 4p 3p; -21p 3p 4p]
        factorP, power_out = LAlatex.factor_out_denominator(power_matrix)
        @test factorP == 1
        @test isequal(power_out, power_matrix)
        power_latex = LAlatex.L_show("A10n=", power_matrix)
        @test !occursin("\\frac{1}{10} \\left", power_latex)
        @test occursin("\\left(\\frac{3}{10}\\right)^{n}", power_latex)
        @test power_latex == "\$\\text{A10n=} \\left(\\begin{array}{rrr}\n-6 \\left(\\frac{3}{10}\\right)^{n} & \\left(\\frac{3}{10}\\right)^{n} & \\left(\\frac{3}{10}\\right)^{n} \\\\\n-21 \\left(\\frac{3}{10}\\right)^{n} & 4 \\left(\\frac{3}{10}\\right)^{n} & 3 \\left(\\frac{3}{10}\\right)^{n} \\\\\n-21 \\left(\\frac{3}{10}\\right)^{n} & 3 \\left(\\frac{3}{10}\\right)^{n} & 4 \\left(\\frac{3}{10}\\right)^{n} \\\\\n\\end{array}\\right)\$\n"

        block_matrix = BlockArray([1//2 1//3; 1//4 1//5], [1, 1], [1, 1])
        factor_block_matrix, out_block_matrix = LAlatex.factor_out_denominator(block_matrix)
        @test factor_block_matrix == 60
        @test out_block_matrix isa BlockArray
        @test axes(out_block_matrix) == axes(block_matrix)
        @test Array(out_block_matrix) == [30 20; 15 12]

        block_vector = BlockArray([1//2, 1//3, 1//4], [1, 2])
        factor_block_vector, out_block_vector = LAlatex.factor_out_denominator(block_vector)
        @test factor_block_vector == 12
        @test out_block_vector isa BlockArray
        @test axes(out_block_vector) == axes(block_vector)
        @test Array(out_block_vector) == [6, 4, 3]
        block_vector_latex = LAlatex.L_show(block_vector)
        @test block_vector_latex == "\$\\frac{1}{12} \\left(\\begin{array}{r}\n6 \\\\ \\hline\n4 \\\\\n3 \\\\\n\\end{array}\\right)\$\n"

        formatted_factored = LAlatex.L_show([1//2 1//3]; number_formatter=x -> x isa Real ? round(Float64(x); digits=1) : x)
        @test occursin("\\frac{1}{6} \\left", formatted_factored)
        @test occursin("3.0 & 2.0", formatted_factored)

        if ok
            pc = getfield(LAlatex, :PythonCall)
            LAlatex.set_backend!(:sympy)
            a_py, b_py = LAlatex.syms(:a, :b)
            latex_py = LAlatex.L_show(a_py, " + ", b_py)
            @test occursin("a", latex_py)
            @test occursin("b", latex_py)

            expr_py = (a_py + b_py)^2
            expanded_py = LAlatex.L_show(expr_py; symopts=(expand=true,))
            @test occursin("a", expanded_py)
            @test occursin("b", expanded_py)

            lc_py = LAlatex.L_show(LAlatex.lc([-(a_py + b_py), a_py - b_py, -a_py], [a_py b_py a_py]))
            @test occursin("-  \\left", lc_py)
            @test occursin("+  \\left", lc_py)
            @test occursin("-  a", lc_py)

            sympy = LAlatex.import_sympy()
            @test strip(LAlatex.L_show(sympy.I)) == "\$i\$"
            @test LAlatex._to_latex_scalar(sympy.I) == LAlatex.to_latex(sympy.I)
            @test LAlatex._to_latex_matrix_entry(2 * a_py) == LAlatex.to_latex(2 * a_py)
            denoms_py = Int[]
            LAlatex._push_sympy_denominator!(denoms_py, sympy.Rational(1, 3))
            @test denoms_py == [3]

            factor_a_half, out_a_half = LAlatex.factor_out_denominator([a_py / 2 a_py])
            @test factor_a_half == 2
            @test LAlatex.to_latex(out_a_half[1, 1]) == LAlatex.to_latex(a_py)
            @test LAlatex.to_latex(out_a_half[1, 2]) == LAlatex.to_latex(2 * a_py)

            factor_sum_half, out_sum_half = LAlatex.factor_out_denominator([(a_py + 1) / 2 a_py])
            @test factor_sum_half == 2
            @test LAlatex.to_latex(out_sum_half[1, 1]) == LAlatex.to_latex(a_py + 1)
            @test LAlatex.to_latex(out_sum_half[1, 2]) == LAlatex.to_latex(2 * a_py)

            p_py = sympy.Rational(3, 10)^a_py
            factor_power_py, out_power_py = LAlatex.factor_out_denominator([p_py a_py])
            @test factor_power_py == 1
            @test LAlatex.to_latex(out_power_py[1, 1]) == LAlatex.to_latex(p_py)
            @test LAlatex.to_latex(out_power_py[1, 2]) == LAlatex.to_latex(a_py)

            large_den_py = big(typemax(Int)) + 2
            large_expr_py = sympy.Rational(1, string(large_den_py)) * a_py
            factor_large_py, out_large_py = LAlatex.factor_out_denominator([large_expr_py a_py])
            @test factor_large_py == large_den_py
            @test LAlatex.to_latex(out_large_py[1, 1]) == LAlatex.to_latex(a_py)

            f_py = LAlatex.mixed_matrix((sympy.Rational(1, 2), a_py), (sympy.Rational(1, 3), b_py))
            factor_py, out_py = LAlatex.factor_out_denominator(f_py)
            @test factor_py == 6
            @test pc.pyconvert(Int, out_py[1, 1]) == 3
            @test pc.pyconvert(Int, out_py[2, 1]) == 2
            @test LAlatex.to_latex(out_py[1, 2]) == LAlatex.to_latex(6 * a_py)
            @test LAlatex.to_latex(out_py[2, 2]) == LAlatex.to_latex(6 * b_py)
        end
    end

    @testset "Formatters" begin
        LAlatex.set_backend!(:symbolics)
        @test LAlatex.bold_formatter(1, 1, 1, "x") == "\\boldsymbol{x}"
        @test LAlatex.italic_formatter(1, 1, 1, "x") == "\\mathit{x}"
        @test LAlatex.color_formatter(1, 1, 1, "x"; color="blue") == "\\textcolor{blue}{x}"
        @test LAlatex.conditional_color_formatter(2, 1, 1, "x") == "\\textcolor{green}{x}"
        @test LAlatex.conditional_color_formatter(-2, 1, 1, "x") == "\\textcolor{red}{x}"
        @test LAlatex.conditional_color_formatter(0, 1, 1, "x") == "x"
        @test LAlatex.highlight_large_values(11, 1, 1, "x"; threshold=10) == "\\boxed{x}"
        @test LAlatex.underline_formatter(1, 1, 1, "x") == "\\underline{x}"
        @test LAlatex.overline_formatter(1, 1, 1, "x") == "\\overline{x}"

        combined = LAlatex.combine_formatters([LAlatex.bold_formatter, LAlatex.color_formatter], 1, 1, 1, "x")
        @test combined == "\\textcolor{red}{\\boldsymbol{x}}"

        @test LAlatex.scientific_formatter(100.0; digits=1) == "1.0e2"
        @test LAlatex.scientific_formatter(-0.0123; digits=2) == "-1.23e-2"
        @test LAlatex.scientific_formatter(0.0; digits=1) == "0.0e0"
        @test LAlatex.percentage_formatter(0.125; digits=1) == 12.5
        @test LAlatex.exponential_formatter(10000.0; digits=1) == "1.0e4"
        @test LAlatex.exponential_formatter(0.00012; digits=2) == "1.2e-4"
        @test LAlatex.exponential_formatter(0.0; digits=1) == 0.0
        @test LAlatex.exponential_formatter(12.345; digits=2) == 12.34

        bold_number = LAlatex.L_show("42 bold -> ", 42; number_formatter=x -> "\\textbf{$x}")
        @test bold_number == "\$\\text{42 bold -> } \\textbf{42}\$\n"

        bold_float = LAlatex.L_show(4.2; number_formatter=x -> LaTeXString("\\mathbf{$x}"))
        @test bold_float == "\$\\mathbf{4.2}\$\n"

        @test LAlatex.tril_formatter(1, 2, 1, "x") == "\\textcolor{red}{x}"
        @test LAlatex.block_formatter(1, 2, 2, "x"; r1=2, r2=3, c1=2, c2=3) == "\\textcolor{red}{x}"
        @test LAlatex.block_formatter(1, 1, 1, "x"; r1=2, r2=3, c1=2, c2=3) == "x"

        blocks = [2, -1, 2]
        colors = ["red", "blue"]
        @test LAlatex.diagonal_blocks_formatter(1, 1, 1, "x"; blocks=blocks, colors=colors) == "\\textcolor{red}{x}"
        @test LAlatex.diagonal_blocks_formatter(1, 3, 3, "x"; blocks=blocks, colors=colors) == "x"
        @test LAlatex.diagonal_blocks_formatter(1, 4, 4, "x"; blocks=blocks, colors=colors) == "\\textcolor{red}{x}"

        pivots = [1, 3]
        @test LAlatex.rowechelon_formatter(1, 1, 1, "x"; pivots=pivots) == "\\textcolor{red}{x}"
        @test LAlatex.rowechelon_formatter(1, 1, 2, "x"; pivots=pivots) == "\\textcolor{red}{x}"
        @test LAlatex.rowechelon_formatter(1, 2, 2, "x"; pivots=pivots) == "x"
        @test LAlatex.rowechelon_formatter(1, 2, 3, "x"; pivots=pivots) == "\\textcolor{red}{x}"
    end

    @testset "L_show helpers" begin
        LAlatex.set_backend!(:symbolics)
        template = LaTeXString("\\mathbb{R}^{" * "\$(n)" * "}")
        tpl = LAlatex.L_interp(template, Dict("n" => 3))
        @test occursin("\\mathbb{R}^{3}", string(tpl))

        @variables x y
        @test LAlatex.L_show_core(x) == "x "

        mixed = LAlatex.mixed_matrix((1//2, x), ((1 + im)//3, 2*y))
        @test size(mixed) == (2, 2)
        @test isequal(mixed[1, 2], x)
        @test isequal(mixed[2, 1], (1 + im)//3)
        mixed_literal = LAlatex.@mixed_matrix [1//2 x; (1 + im)//3 2*y]
        @test mixed_literal[1, 1] == 1//2
        @test isequal(mixed_literal[2, 2], 2*y)

        mats = [[reshape(1:4, 2, 2), :none], [nothing, reshape(5:8, 2, 2)]]
        rounded = LAlatex.round_matrices(mats; digits=0)
        @test rounded[1][1] == [1 3; 2 4]
        @test rounded[1][2] === nothing

        np = LAlatex.print_np_array_def([1, 2, 3]; nm="v")
        @test occursin("np.array([1, 2, 3])", np)

        joined = LAlatex.L_show((:x, :y); separator=L",\\quad")
        @test occursin("\\quad", joined)

        empty_group = LAlatex.L_show(LAlatex.set())
        @test occursin("\\left\\{", empty_group)
        @test occursin("\\right\\}", empty_group)

        unfactored_group = LAlatex.L_show(LAlatex.set([1//2 1//3]; factor_out=false))
        @test occursin("\\frac{1}{2}", unfactored_group)
        @test !occursin("\\frac{1}{6} \\left", unfactored_group)

        expanded_group = LAlatex.L_show(LAlatex.set((x + y)^2; symopts=(expand=true,)))
        @test !occursin("\\left(y + x\\right)^{2}", expanded_group)
        @test occursin("x^{2}", expanded_group) || occursin("x^2", expanded_group)

        cases_latex = LAlatex.L_show(
            "T(v) = ",
            LAlatex.cases(
                [x, 0] => L"v \in \operatorname{span}\{e_1\}",
                ([0, y], "otherwise"),
            ),
        )
        @test occursin("\\begin{cases}", cases_latex)
        @test occursin("\\left(\\begin{array}{r}\nx \\\\\n0 \\\\\n\\end{array}\\right), & v \\in \\operatorname{span}\\{e_1\\}", cases_latex)
        @test occursin("\\text{otherwise}", cases_latex)

        expanded_cases = LAlatex.L_show(LAlatex.cases((x + y)^2 => L"x > 0"); symopts=(expand=true,))
        @test !occursin("\\left(y + x\\right)^{2}", expanded_cases)
        @test occursin("x^{2}", expanded_cases) || occursin("x^2", expanded_cases)
        @test_throws ArgumentError LAlatex.L_show(LAlatex.cases(x))

        aligned_latex = LAlatex.L_show(
            LAlatex.aligned(
                [L"Ax", L"=", [x, y]],
                (L"x", L"\in", L"\mathcal{N}(A)"),
                L"\dim\mathcal{N}(A)" => L"n - \operatorname{rank}(A)",
            ),
        )
        @test occursin("\\begin{aligned}", aligned_latex)
        @test occursin("Ax & = & \\left(\\begin{array}{r}\nx \\\\\ny \\\\\n\\end{array}\\right)", aligned_latex)
        @test occursin("x & \\in & \\mathcal{N}(A)", aligned_latex)
        @test occursin("\\dim\\mathcal{N}(A) & = & n - \\operatorname{rank}(A)", aligned_latex)

        expanded_aligned = LAlatex.L_show(LAlatex.aligned([(x + y)^2, L"=", x]); symopts=(expand=true,))
        @test !occursin("\\left(y + x\\right)^{2}", expanded_aligned)
        @test occursin("x^{2}", expanded_aligned) || occursin("x^2", expanded_aligned)
        @test_throws ArgumentError LAlatex.L_show(LAlatex.aligned(x))
        @test_throws ArgumentError LAlatex.L_show(LAlatex.aligned([]))

        @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1], [x y]))
        @test_throws ArgumentError LAlatex.L_show(LAlatex.lc([1, 2, 3], [x y]))
    end
end
