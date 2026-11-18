# Quoted operator regression cases

Run `python3 run_tests.py --candidate /absolute/path/to/interpreter --gfortran
/absolute/path/to/gfortran`. The runner uses strict GNU Fortran 2018 with runtime
checks for successful comparisons. Rejection cases test malformed token sequences
or explicitly retained subset boundaries; they are not execution comparisons.

All fixtures here are synthetic. Existing original-body provenance and drivers
are retained in `tests/repeat_intrinsic` and `tests/release031_integration`.
See `docs/QUOTED-OPERATORS.md` for scope and the exact original line repaired.
