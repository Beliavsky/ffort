# Allocatable descriptor associations

Run `python run_tests.py --candidate PATH --gfortran PATH`.

The suite checks numeric rank-one/two allocatable IN/OUT/INOUT dummies,
allocation status and exact bounds, nested forwarding, module actuals,
zero-sized descriptors, retained undefined flags, same-object aliases and
callee/caller live-storage caps. Cases are classified separately as executed
GNU comparisons, invalid-source GNU rejections or interpreter-only safety rules.

`utilities_unchanged_alloc_sub.f90` contains exact normalized-text extracts of
both `alloc_sub_vec_real` and `alloc_sub_vec_int`. The runner verifies the complete
original 338883-byte source fingerprint and exact body inclusion before running.
The wrapper calls both procedures for first allocation, OUT replacement and
empty arrays. This is not execution of the complete utility module.
