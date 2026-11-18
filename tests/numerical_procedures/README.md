# Numerical procedures regression suite

Run `python3 test_runner.py` for the independent runner's own checks. Run
`python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`
for interpreter and compiler-oracle validation. The runner never uses a compiler
as the interpreter's execution backend.

The corpus preserves the two requested examples as `cases/exact_black_scholes.f90`
and `cases/exact_module_subroutine.f90`. Additional programs exercise:

- Black–Scholes benchmark prices, put–call parity, zero volatility, expiration,
  negative rates, very short/long maturity, small/large scales and deep in/out-of-money inputs.
- Nonpositive spot/strike and negative volatility/maturity, including diagnostic text
  and absence of partially emitted PRINT output.
- REAL64 precision and conversion, kind-qualified literals, typed/PURE functions,
  EXP/LOG/SQRT/ERFC/ABS/MAX and arithmetic.
- Module/internal subroutines, call frames, character dummy arguments, RETURN,
  formatted PRINT, USE ONLY and PUBLIC/PRIVATE visibility.
- Rejection of mismatched argument counts/types/kinds, private/excluded names,
  undefined or unsupported kinds, prohibited writes, unsupported syntax, cycles,
  and compile-time output leakage.

`generate_cases.py` regenerates the corpus from the unchanged examples and
independent mathematical formulas. Numerical prices use Python standard-library reference values,
not output harvested from the candidate. REAL64 checks use tight case-specific
relative and absolute tolerances. Explicit format checks compare spaces exactly.
The harness itself tests tight precision, layout mismatch, nonfinite output,
missing diagnostics, wrong exit status and output leakage.

GNU Fortran compiles each source in a fresh temporary directory, with
`-std=f2018 -pedantic-errors -fcheck=all -O0`. A reference classified as `run`
executes and checks its output; `runtime` must fail with the expected diagnostic;
`reject` must fail compilation; and `compile` checks valid syntax only. The
`skip` cases are interpreter-specific safety boundaries and do not claim a
Fortran compiler oracle. Results record per-case commands' output, return codes,
errors, corpus/source hashes and the candidate executable hash.
