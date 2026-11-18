# Scalar allocatable CHARACTER tests

Run `python3 tests/scalar_allocatable_character/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran`.
Run `python3 tests/scalar_allocatable_character/test_runner.py` for harness self-tests.

The manifest distinguishes executable GNU agreements, compile-only safety or subset boundaries and GNU compilation rejections. Expected output is independently asserted, not learned from candidate output. Compiler invocations use fresh temporary directories with `-std=f2018 -pedantic-errors -fcheck=all -O0`. The complete original demo uses exact line comparison; all other execution cases assert semantics internally with ERROR STOP.

See [the feature contract](../../docs/SCALAR-ALLOCATABLE-CHARACTER.md). Upstream source and license hashes are in `upstream.json`.
