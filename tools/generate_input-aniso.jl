# Example:
# julia --project=. tools/generate_input-aniso.jl -o '/tmp/data/aniso_1M_1e-3.jld2' --nnz=1000000 --xi=1e-3

using FromFile
using ArgParse
using Laplacians
using Statistics
using SparseArrays
using LinearAlgebra
using JLD2
using CodecZlib  # CodecZlib must be explicitly imported for compression in JLD2 to work.
using Random

function parse_cmdargs()
  s = ArgParseSettings()
  @add_arg_table s begin
    "-o"
    help = "output file path"
    arg_type = String
    required = true
    "--nnz"
    help = "Argument `nnz` for the function `aniso_grid_sddm()`(https://github.com/danspielman/Laplacians.jl/blob/c18861fdb14bd796acdcc93b9c5c58744023f424/src/graphGenGeom.jl#L684C10-L684C25)"
    arg_type = Int
    required = true
    "--xi"
    help = "Argument `xi` for the function `aniso_grid_sddm()`(https://github.com/danspielman/Laplacians.jl/blob/c18861fdb14bd796acdcc93b9c5c58744023f424/src/graphGenGeom.jl#L684C10-L684C25)"
    arg_type = Float64
    required = true
    "--seed"
    help = "Seed for the randomizer"
    arg_type = Int
    required = false
    default = 0
  end
  return parse_args(s)
end

function main()
  local args = parse_cmdargs()
  @show args

  local outfile = args["o"]
  local nnz::Int = args["nnz"]
  local xi::Float64 = args["xi"]
  local seed::Int = args["seed"]

  local M = aniso_grid_sddm(nnz, xi)  # `M` is a Laplacian
  M = dropzeros(sparse(M))
  local n::Int = size(M, 1)  # `n` is the number of vertices

  local rng = Xoshiro(seed)  # pick a random number generate with a fixed seed
  local x::Vector{Float64} = randn(rng, n)  # generate a random true solution `x`
  x .-= mean(x)  # ensure that `sum(x) ≈ 0`

  local b::Vector{Float64} = M * x  # generate the RHS for `Lx = b`
  x ./= norm(b)  # normalize both `x` and `b`
  b ./= norm(b)
  x = dropzeros(sparse(x))
  b = dropzeros(sparse(x))

  input_spec = Dict()
  input_spec["mat"] = sparse(M)
  input_spec["b"] = sparse(b)
  input_spec["x"] = sparse(x)

  mkpath(dirname(outfile))
  jldsave(outfile, true; mat = M, b, x)
end
main()
