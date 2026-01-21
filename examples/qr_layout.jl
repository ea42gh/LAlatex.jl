using LAlatex
using BlockArrays

Q = [1 0; 0 1]
R = [2 1; 0 3]
qr_block = BlockArray([Q zeros(2, 2); zeros(2, 2) R], [2, 2], [2, 2])

println(L_show("Q R = ", qr_block; arraystyle=:barray))
