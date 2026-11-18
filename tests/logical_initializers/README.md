# Complete logical declaration initializers

Fourteen independent cases compare the interpreter with GNU Fortran: 11 executions and 3 expected rejections. Coverage includes scalar/array PARAMETER declarations, mutable initialization, multiple declarators, parentheses, NOT/AND/OR/EQV/NEQV precedence, and malformed, mistyped or unbound expression tails.

Run `python3 tests/logical_initializers/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran --result results.json`. The runner checks compile-only mode, status, output, diagnostics, timeouts, source hashes and the candidate hash. It supplements the raw producer/adapter mutation test in `test/test_logical_initializer_frontend.f90`. See vendor patch 0020 for the upstream parsing correction.
