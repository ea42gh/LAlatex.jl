using Test
using LAlatex
using Symbolics

"""
Return (true, sympy) if SymPy is importable via PythonCall, else (false, nothing).
This keeps tests CI-friendly when SymPy is not installed.
"""
function _sympy_available()
    try
        sympy = LAlatex.import_sympy()
        return true, sympy
    catch
        return false, nothing
    end
end

ok, sympy = _sympy_available()

@testset "LAlatex" begin
    @testset "Symbolics default" begin
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

        @test_throws ArgumentError LAlatex.syms(:xr; real=true)
        @test_throws ArgumentError LAlatex.@syms q :real => true
    end

    @testset "SymPy integration" begin
        if !ok
            @test_skip "SymPy not available in the PythonCall environment"
        else
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

            LAlatex.set_backend!(LAlatex.Backend.SymbolicsBackend())
            LAlatex.@syms t
            @test t isa Symbolics.Num
        end
    end
end
