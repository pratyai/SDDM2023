# Example
# julia --project=. tools/bench_with_statusquo_approx_chol.jl -i aniso.spec -o aniso.out.spec

using FromFile
using ArgParse
using CSV
using DataFrames
using Laplacians
using Statistics
using SparseArrays
using LinearAlgebra
using JLD2

function parse_cmdargs()
  s = ArgParseSettings()
  @add_arg_table s begin
    "-i"
    help = "path to the input spec"
    arg_type = String
    required = true
    "-o"
    help = "path to store the output spec (if empty, will print on stdout)"
    arg_type = String
    required = false
    default = ""
  end
  return parse_args(s)
end

function main()
  local args = parse_cmdargs()
  @show args

  local inspec::String = strip(args["i"])
  local outspec::String = strip(args["o"])

  local t = CSV.read(inspec, DataFrame)
  local out = DataFrame(
    name = String[],
    cholesky_time = Float64[],
    solve_time = Float64[],
    pcg_iters = Int[],
    x_error = Float64[],
    b_error = Float64[],
    b_norm = Float64[],
  )

  for r in eachrow(t)
    @show r

    # Various setup wroks.
    local M = missing
    local b = missing
    local x_corr = missing
    if r[:format] == "JLD2"
      M, b, x_corr = load(r[:input_file], "mat", "b", "x")
    end
    local params = ApproxCholParams(:deg, 0, r[:split], r[:merge])
    local pcgits = Int[0]  # Read the documentation for `approxchol_sddm()` for the reason.

    #= Benchmarking process begins =#

    # TODO: warm up
    # TODO: error handling

    GC.gc()  # first get the garbage collection out of the way

    local t0 = time()
    local solver = approxchol_sddm(
      M;
      params = params,
      tol = r[:pcg_rel_tol],
      maxits = r[:pcg_max_iter],
      pcgIts = pcgits,
    )
    local t_fact = time()
    local x = solver(b)
    local t_solv = time()

    #= Benchmarking process ends =#

    x .-= mean(x)
    local x_error = norm(x - x_corr)
    local b_error = norm(M * x - b)
    local b_norm = norm(b)
    push!(
      out,
      Dict(
        :name => r[:name],
        :cholesky_time => t_fact - t0,
        :solve_time => t_solv - t0,
        :pcg_iters => pcgits[1],
        :x_error => x_error,
        :b_error => b_error,
        :b_norm => b_norm,
      ),
    )
  end

  if outspec == ""
    @show out
  else
    mkpath(dirname(outspec))
    CSV.write(outspec, out)
  end
end
main()
