#=
  HYPRE_HOME needs to be set to where Hypre lives for using MATLAB,
  for example you could put the following in .bash_profile
  export HYPRE_HOME="/Users/janedoe/hypre"

  WARNING: currently needs the above line AND NO / (slash) at end, which is not common?

  and need gtimeout, which can get from brew install coreutils
=#

using CSV
using DataFrames

include("juliaSaveMatrixVector.jl")
function timeLimitHypre(limit, M, b; verbose=false, num_procs=1, tol=1e-8)
    # function timeLimitHypre(limit, M, b; tol::Real=1e-8, maxits=1000, verbose=false, num_procs=2)

    
    solverHome = ENV["HYPRE_HOME"]
    scriptpath = "$(solverHome)/src/test/ij_print"
    
    matname = "tmpFromJulia_mat.txt"
    vecname = "tmpFromJulia_vec.txt"

    juliaSaveMatrixVector(matname,M,vecname,b)

    tmpOutFileName_relres = "relres.out"
    tmpOutFileName_setuptime = "setup.timing.out"
    tmpOutFileName_solvetime = "solve.timing.out"

    bt = Inf
    st = Inf
    err = Inf
    iter = Inf

    #cmd = `gtimeout $(limit) $(scriptpath) --verbose=false --muelu-xml=$(scripxmlsettings) --tol=1e-6 --max-iters=$(maxits) --filepath=$(matpath) --rhsfile=$(vecpath) --outputfile=$(tmpOutFileName)`

    cmd = `timeout $(limit) mpirun -np $(num_procs) $(scriptpath) -solver 1 -fromonecsrfile $(matname) -rhsfromonefile $(vecname) -print -tol $(tol)`
    
    try
        run(cmd)
        
        bt = CSV.read(tmpOutFileName_setuptime, DataFrame; header=false)[1,1]
        st = CSV.read(tmpOutFileName_solvetime, DataFrame;header=false)[1,1]
        iter = CSV.read("pcgiter.out", DataFrame; header=false)[1,1]
        err = CSV.read(tmpOutFileName_relres, DataFrame;header=false)[1,1]
    catch e
        errtrace = backtrace()
        msg = sprint(showerror, e, errtrace)
        println(msg)
        println("Hypre script died")
    end
        
    if verbose
      println("Build Time: ", bt)
      println("Solve Time: ", st)
      println("Iterations: ", iter)
      println("error: ", err)
      #d1 = DateTime(start,"d-u-yyyy H:M:S")
      #println("Time to load and start Matlab: $(d1-DateTime(t0))/1000)")
    end

    return (st, bt, iter, err)
end
