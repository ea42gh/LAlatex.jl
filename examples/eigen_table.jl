using LAlatex
using BlockArrays

eigvals = [2, -1]
eigvecs = [1 0; 0 1]
eig_table = BlockArray([eigvals'; eigvecs], [1, 2], [2])

println(L_show("eig = ", eig_table; arraystyle=:barray))
