using FromFile
using ArgParse
using CSV
using DataFrames

function parse_cmdargs()
  s = ArgParseSettings()
  @add_arg_table s begin
    "-o"
    help = "path to store the input spec (if empty, will print on stdout)"
    arg_type = String
    required = false
    default = ""
    "infiles"
    help = "list of input JLD2 files containing the specs"
    arg_type = String
    nargs = '+'
    required = true
  end
  return parse_args(s)
end

function main()
  local args = parse_cmdargs()
  @show args

  local infiles::Vector{String} = args["infiles"]
  local specfile::String = strip(args["o"])

  local t = DataFrame(
    name = [splitext(basename(f))[1] for f in infiles],
    format = ["JLD2" for _ = 1:length(infiles)],
    input_file = [f for f in infiles],
  )
  if specfile == ""
    @show t
  else
    mkpath(dirname(specfile))
    CSV.write(specfile, t)
  end
end
main()
