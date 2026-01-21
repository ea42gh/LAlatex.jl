from juliacall import Main as jl


jl.seval("using LAlatex")
print(jl.LAlatex.L_show("A = ", [[1, 2], [3, 4]]))
