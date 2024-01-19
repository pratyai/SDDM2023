# A flexible structure for creating benchmarks for Laplacian/SDDM solvers.

## Overview

We expect to compare the performances of solver implementations that can have very different methods and relevant metrics. More importantly, these implementations can be from very different languages too, which can make it very difficult to integrate with a unified test harness.

So, we want to have a framework of performance measurement that can interface over simple files. Then we can write simple programs in the most convenient way (e.g. usually in the native language of the implementation that we are measuring), which can read a structured input and produce a structured output containing the various metrics collected during the benchmarking process.

These strucutured input and output files should be human readable, but also easy to work with simple scripts or programs --- we will assume CSV format here. But if necessary, they can contain URLs to other files that may have more complicated or unreadable strucuture (e.g. matrix or vector files if we need to inspect them).

We also need the structure of these files to be sufficiently flexible, so that very different kinds of solvers or experiments can report different kinds of metrics which can still be joined, when applicable, to make a comparison.

## Input Spec

### Basic

The following columns are required:

- Name (`name`: `string`): A short name identifying the particular problem described in this entry.
- Format (`format`: `string`): A keyword describing the format of the rest of this entry. We will assume [JLD2](https://github.com/JuliaIO/JLD2.jl) format here.

### JLD2 format

The following columns are required for JLD2 format.

- Input File (`input_file`: `string`): Since JLD2 format can contain multiple named variables, this will contain the all the matrix & vector type variables necessary to specify the problem.

There can be other optional columns as well that may be important for a particular implementation or algorithm. For example, the following optional columns are useful for our solver that relies on Preconditioned Conjugate Gradient (PCG) algorithm:

- Relative PCG Tolerance (`pcg_rel_tol`: `float`): The error tolerance (w.r.t. the L2-norm of the RHS) for PCG algorithm which determines how many iterations the algorithm needs before producing an acceptable solution.
- Maximum Iterations (`pcg_max_iter`: `int`): The maximum number of iterations the PCG algorithm is allowed to take.

For our particular approximate Laplacian solver, the following optional columns can also be useful:

- Split (`split`: `int`): Number of initial splits per edge on the original graph. Typically, it should be set to a value of `2`.
- Merge (`merge`: `int`): When averaging multiedges, the maximum number of splits to keep. Typically, it should be set to the same value as `split`.

The following variables are to be expected in `input_file`:

- SDDM/Laplacian Matrix: For a SDDM/Laplacian solver, the multiedges are not very relevant. So, we will just keep the SDDM/Laplacian matrix here. We explicitly store the information to construct a `SparseMatrixCSC`` as follows:
  - (`mat_m`: `int`)
  - (`mat_n`: `int`)
  - (`mat_colptr`: `vector<int>`): 1-indexed.
  - (`mat_rowval`: `vector<int>`): 1-indexed.
  - (`mat_nzval`: `vector<float>`)
- RHS (`b`: `vector<float>`): This is the RHS `b` of the system `Lx = b`.
- True solution (`x`: `vector<float>`): This is _one_ of the correct solution for the system `Lx = b` (ignoring the numerical errors induced by floating-point operations). We will adopt the convention of having an `x` where `sum(x) == 0`.

## Output Spec

### Basic

The following columns are required:

- Name (`name`: `string`): A short name identifying the particular problem described in this entry.

Every benchmarking experiemnts can add additional columns containing scalar metrics or an URL to different files with complicated structures. There is no other real requirement than this. But for making a good comparisons, the different experiments should agree upon the semantics of the column (identified by its header) beforehand.

### Approximate Cholesky Factoisation Solvers

For example, for our iterative solvers, the following columns are also required:

- Time to Cholesky factorise (`cholesky_time`: `Duration`): If we expect to reuse the factorisation, it can be an important metric to look at.
- Time to Solve (`solve_time`: `Duration`): The time it takes to solve `Lx=b` up to the given tolerance, including the factorisation time.
- PCG Iterations (`pcg_iters`: `int`): The number of PCG iteration it takes for the solution.
- Solution Error (`x_error`: `float`): L2-norm of `x_ours - x_true` (`x_true` is the `x` from the input spec).
- RHS Error (`b_error`: `float`): L2-norm of `Lx - b` (`b` is from the input spec).
