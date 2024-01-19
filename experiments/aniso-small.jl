using Printf

const DATA_ROOT = "/tmp/aniso_small/data"
const SPEC_ROOT = "/tmp/aniso_small/spec"
mkpath(DATA_ROOT)
mkpath(SPEC_ROOT)

aniso_data_path(nnz::Int, xi::Float64) = @sprintf("%s/aniso_%d_%g.jld2", DATA_ROOT, nnz, xi)

function data_gen(path::String, nnz::Int, xi::Float64)
  local cmd = Cmd([
    "julia",
    "--project=.",
    "tools/generate_input-aniso.jl",
    @sprintf("-o %s", path),
    @sprintf("--nnz=%d", nnz),
    @sprintf("--xi=%lf", xi),
  ])
  run(cmd)
end

function spec_gen(name::String, paths::Array{String})
  local cmd = Cmd(
    vcat(
      [
        "julia",
        "--project=.",
        "tools/produce_input_spec.jl",
        @sprintf("-o %s/%s.inspec", SPEC_ROOT, name),
      ],
      paths,
    ),
  )
  run(cmd)
end

function spec_bench(name::String)
  local cmd = Cmd([
    "julia",
    "--project=.",
    "tools/bench_with_statusquo_approx_chol.jl",
    @sprintf("-i %s/%s.inspec", SPEC_ROOT, name),
    @sprintf("-o %s/%s.outspec", SPEC_ROOT, name),
  ])
  run(cmd)
end

datapaths = String[]
for nnz in Int[1e6], xi in Float64[1e-3, 1e-2, 1e-1, 1, 1e1, 1e2, 1e3]
  local path = aniso_data_path(nnz, xi)
  @show path
  push!(datapaths, path)
  if !isfile(path)
    data_gen(path, nnz, xi)
  else
    println("skipping existing problem: " * path)
  end
end

spec_gen("aniso-small", datapaths)
spec_bench("aniso-small")
