# Array expression actual arguments

This focused regression suite preserves the user's exact `mean(x),mean(x**2)`
program unchanged in `cases/user_exact_random_power.f90` and in
`examples/mean_random_power.f90`. Its message provenance is in `manifest.json`.
No source rewriting, semantic-error suppression or adapter bypass is involved.

Run `python3 generate_cases.py`, `python3 test_runner.py`, then
`python3 run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran`.
The root `scripts/verify.py` includes the harness and differential runs.

The 49 cases cover the exact random program, deterministic analytic means,
integer/wide-integer and real exponents, unary minus, arithmetic, nested
expressions/intrinsics, array constructors, keywords, INTEGER4/8 parameter-expression actuals and exact values beyond 2**53,
empty arrays, rank-two
arrays and rank-reducing/reversed sections. REAL kind/type/rank mismatches and
known shape mismatches must still be rejected. Dynamic shape mismatch and
uninitialized-element failures are interpreter runtime-policy tests, with GNU
used only for compilation.

The exact 1000-element and additional 100000-element random programs are separately checked against each runtime's own contract:
two finite values in [0,1), and mean(x)**2 <= mean(x**2) <= mean(x), with a small
roundoff allowance. Only the interpreter is required to repeat its documented
per-execution seeded result. No candidate/GNU random values or sequences are
compared. Deterministic programs use independently specified expectations with
1e-13 relative/absolute tolerance. Compilation uses GNU Fortran in Fortran 2018
pedantic mode with runtime checking. Reports retain actual streams, exits,
compiler options, tool versions, source hashes and the candidate hash.

Native tests `test_array_actual_producer.f90` check strict producer acceptance,
rejections and resolved element type/kind/rank. `test_array_actual_frontend.f90`
requires rejection of nine deliberately forged IR type/rank/shape/operator or
operand disagreements. Neither replaces the independent GNU comparison.

Wide INTEGER outputs are compared exactly with decimal/integer arithmetic, never
converted through binary floating point. Eleven harness self-tests include
rejection of one-unit errors above 2**53.
