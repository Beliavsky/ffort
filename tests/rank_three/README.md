# Bounded rank-three arrays

The fixture generator computes first-index-fastest expectations in Python without importing interpreter implementation code. The harness checks both CLI `--check` and execution, exact exit classes, diagnostics, output leaks, and numerical/token agreement. GNU Fortran compiles each fixture in a fresh temporary directory and is an independent oracle, not an interpreter backend.

Run:

```
python tests/rank_three/generate_cases.py
python tests/rank_three/test_runner.py
python tests/rank_three/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran /absolute/path/to/gfortran
```

Coverage includes rectangular and zero-size arrays, all three bound inquiries, integer/real/logical/character elements, whole-array arithmetic, all seven combinations of scalar and triplet selectors, rank-one/two/three sections, reverse/interleaved/overlapping assignment, dynamic third-axis bounds, assumed-shape copy-back, automatic local and result arrays, optional supplied/absent actuals, elemental functions and subroutines, and equal-total-size shape disagreements.

Safety cases test the 131072-element cap and three-factor overflow. Five huge-shape/cap cases deliberately skip GNU compilation: they test interpreter safety policy and are not claimed as GNU differential successes. Remaining unsupported cases keep rank-four, PACK, reductions, and RESHAPE outside this increment.

`xutilities_tensor_original.f90` contains the original six-line `tensor` procedure from the supplied xutilities source, unchanged apart from normalized line endings. `cases/original_xutilities_tensor.f90` surrounds this exact body with a synthetic module/kind declaration and a synthetic executable driver. This verifies the actual utility procedure, not the complete xutilities module. The manifest records a SHA-256 of its exact normalized body.

The native `test/test_rank_three_frontend.f90` independently mutates third-axis bounds, extent/rank caches, source element/target subscript IDs, triplet operands and cycles, automatic bounds, and same-size differing shapes. All forged IR must be rejected by the adapter.

Recorded focused run: 50/50 candidate cases, 45/45 GNU-oracle cases, five explicit GNU skips, and 12/12 harness self-tests. See `results.json` for combined evidence and `gnu-results.json` for the standalone compiler oracle.

The added RANDOM_NUMBER fixtures compare only range, shape, and untouched-element invariants with GNU. PARAMETER fixtures cover scalar initialization, constant sections, and constant bounds. A module counter in an IMPURE ELEMENTAL function checks that a third-index expression is evaluated once for an element read, write, and scalar dummy binding. The separate native runtime test covers 12 malformed-IR cases with atomic stdout errors and seeded RNG count/range/repeatability.

The historical `limited_allocatable` source is retained unchanged and now expected to pass; rank-three allocation has its own suite in `tests/rank_three_allocatables`.
