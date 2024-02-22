using Laplacians
using MATLAB
using LinearAlgebra
using Random

# A = chimera(10000,25);  # returns adj mat
A = uni_chimera(10000,25);  # returns adj mat
L = lap(A);
n = size(L, 1);

Random.seed!(1);
b = L * Random.randn(n);
b ./= norm(b);

mf = MATLAB.MatFile("fromJulia.mat", "w");
put_variable(mf, "la", L)
put_variable(mf, "b", b)
put_variable(mf, "tol", 1e-8)
put_variable(mf, "maxits", 1000)
close(mf)
