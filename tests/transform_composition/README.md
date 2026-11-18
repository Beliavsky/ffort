# PACK/RESHAPE/COUNT composition

Twenty-six independently specified programs cover nested transformations in both
directions, CHARACTER round trips, LOGICAL and exact INTEGER(8) values,
COUNT-dependent results, PACK-generated ORDER and PAD, parameter composition,
unevaluated KIND with undefined or invalid-valued inputs, and empty outputs.
Twenty valid programs are checked against hand-written literal expectations and
strict GNU Fortran execution. Six runtime safety cases ensure an empty outer
result does not hide an invalid inner mask, ORDER, VECTOR or extent. They are
not executed by the compiler oracle.

Run `python3 tests/transform_composition/run_tests.py --candidate PATH --gfortran gfortran`.
The standard verifier includes these checks.
