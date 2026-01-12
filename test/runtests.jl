using Test
using LaTeXStrings
using PythonCall

if !haskey(ENV, "JULIA_PYTHONCALL_EXE") || isempty(ENV["JULIA_PYTHONCALL_EXE"])
    for name in ("python3", "python")
        exe = Sys.which(name)
        if exe !== nothing
            ENV["JULIA_PYTHONCALL_EXE"] = exe
            @info "Set JULIA_PYTHONCALL_EXE for tests" exe
            break
        end
    end
end

using LAlatex
using Symbolics

"""
Return (ok, sympy, exe) where `ok` is true if SymPy is importable via PythonCall.
`exe` is the Python executable reported by PythonCall when available.
"""
function _sympy_available()
    try
        exe = try
            PythonCall.pyconvert(String, PythonCall.pyimport("sys").executable)
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
    @testset "Symbolics default" begin
        LAlatex.set_backend!(:symbolics)
        @test LAlatex.get_backend() isa LAlatex.Backend.SymbolicsBackend

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
            xs = LAlatex.syms_sympy(:x)
            ys = LAlatex.syms_sympy(:y; real=true, positive=true)
            @test string(xs) == "x"
            @test string(ys) == "y"

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
        @test LAlatex.to_latex("= 0") == "= 0"
        @test LAlatex.to_latex(LaTeXString("\\alpha + 1")) == "\\alpha + 1"
        @test LAlatex.to_latex('x') == "\\text{x}"
        @test LAlatex.to_latex(3//4) == "\\frac{3}{4}"
        @test LAlatex.to_latex(2 + 0im) == "2"
        @test LAlatex.to_latex(0 + 1im) == "\\mathit{i}"
        @test LAlatex.to_latex(0 + -1im) == "-\\mathit{i}"
        @test LAlatex.to_latex(:alpha) == "alpha"

        LAlatex.@syms z
        latex_z = LAlatex.to_latex(z)
        @test occursin("z", latex_z)

        if ok
            sp = LAlatex.syms(:sp; backend=:sympy, real=true)
            latex_sp = LAlatex.to_latex(sp)
            @test occursin("sp", latex_sp)
        end

        LAlatex.set_backend!(:symbolics)
        alpha = LAlatex.syms("α_1")
        latex_alpha = LAlatex.to_latex(alpha)
        @test occursin("\\alpha", latex_alpha) || occursin("α", latex_alpha)
        @test occursin("_1", latex_alpha)
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

        @test LAlatex.scientific_formatter(100.0; digits=1) == "100.0e2.0"
        @test LAlatex.percentage_formatter(0.125; digits=1) == 12.5
        @test LAlatex.exponential_formatter(10000.0; digits=1) == "1.0e4.0"
        @test LAlatex.exponential_formatter(12.345; digits=2) == 12.34

        @test LAlatex.tril_formatter(1, 2, 1, "x") == "\\textcolor{red}{x}"
        @test LAlatex.block_formatter(1, 2, 2, "x"; r1=2, r2=3, c1=2, c2=3) == "\\textcolor{red}{x}"
        @test LAlatex.block_formatter(1, 1, 1, "x"; r1=2, r2=3, c1=2, c2=3) == "x"

        blocks = [2, -1, 2]
        colors = ["red", "blue"]
        @test LAlatex.diagonal_blocks_formatter(1, 1, 1, "x"; blocks=blocks, colors=colors) == "\\textcolor{red}{x}"
        @test LAlatex.diagonal_blocks_formatter(1, 3, 3, "x"; blocks=blocks, colors=colors) == "x"
        @test LAlatex.diagonal_blocks_formatter(1, 4, 4, "x"; blocks=blocks, colors=colors) == "\\textcolor{red}{x}"

        pivots = [1, 3]
        @test LAlatex.rowechelon_formatter(1, 1, 1, "x"; pivots=pivots) == "\\textcolor{red}{\\boldsymbol{x}}"
        @test LAlatex.rowechelon_formatter(1, 1, 2, "x"; pivots=pivots) == "\\textcolor{red}{\\boldsymbol{x}}"
        @test LAlatex.rowechelon_formatter(1, 2, 2, "x"; pivots=pivots) == "x"
        @test LAlatex.rowechelon_formatter(1, 2, 3, "x"; pivots=pivots) == "\\textcolor{red}{\\boldsymbol{x}}"
    end

    @testset "L_show helpers" begin
        LAlatex.set_backend!(:symbolics)
        template = LaTeXString("\\mathbb{R}^{" * "\$(n)" * "}")
        tpl = LAlatex.L_interp(template, Dict("n" => 3))
        @test occursin("\\mathbb{R}^{3}", string(tpl))

        @variables x y
        @test LAlatex.L_show_core(x) == "x "
        matrix_latex = LAlatex.L_show([x y; y x])
        @test occursin("x", matrix_latex)
        @test occursin("y", matrix_latex)
        @test !occursin(" &  &", matrix_latex)

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

        expr = (x + y)^2
        expanded = LAlatex.L_show(expr; symopts=(expand=true,))
        @test occursin("x^2", expanded) || occursin("x^{2}", expanded)

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

        if ok
            LAlatex.set_backend!(:sympy)
            a_py, b_py = LAlatex.syms(:a, :b)
            latex_py = LAlatex.L_show(a_py, " + ", b_py)
            @test occursin("a", latex_py)
            @test occursin("b", latex_py)

            expr_py = (a_py + b_py)^2
            expanded_py = LAlatex.L_show(expr_py; symopts=(expand=true,))
            @test occursin("a", expanded_py)
            @test occursin("b", expanded_py)

            sympy = LAlatex.import_sympy()
            f_py = LAlatex.mixed_matrix((sympy.Rational(1, 2), a_py), (sympy.Rational(1, 3), b_py))
            factor_py, out_py = LAlatex.factor_out_denominator(f_py)
            @test factor_py == 6
            @test PythonCall.pyconvert(Int, out_py[1, 1]) == 3
            @test PythonCall.pyconvert(Int, out_py[2, 1]) == 2
            @test LAlatex.to_latex(out_py[1, 2]) == LAlatex.to_latex(6 * a_py)
            @test LAlatex.to_latex(out_py[2, 2]) == LAlatex.to_latex(6 * b_py)
        end
    end
end
