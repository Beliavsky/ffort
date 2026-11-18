# Independent argument-association checks

This suite tests the 0.8.0 scalar `INTENT(OUT)`/`INTENT(INOUT)` and rank-one
assumed-shape argument increment. GNU Fortran is an independent reference
compiler, never an execution backend for the interpreter.

## Reproduce

After `fpm build --profile debug`, supply the resulting interpreter executable:

```sh
python3 tests/argument_association/test_runner.py
python3 tests/argument_association/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
python3 tests/argument_association/run_section_matrix.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The aggregate `python3 scripts/verify.py` runs these commands alongside all
previous suites. The runners accept one executable path, not a shell command,
and compile each GNU fixture in a fresh temporary directory to avoid `.mod`
contamination. GNU flags are `-std=f2018 -pedantic-errors -fcheck=all -O0`.
`generate_cases.py` regenerates the checked-in source corpus and manifest.

## Corpus and independent expectations

`manifest.json` contains 145 cases:

- 78 successful programs have explicitly specified expected values. Both the
  interpreter and GNU execution must match those values, not merely each other.
- 34 interpreter safety-policy failures must pass `--check`, fail execution with
  status 2 and the intended diagnostic, and preserve exactly the specified
  earlier output. GNU compilation establishes source validity; GNU execution is
  deliberately not an oracle for undefined reads, conservative alias rejection,
  runtime shape/dimension checks, or interpreter resource limits.
- 28 invalid programs must be rejected by GNU and by the interpreter before any
  program output. They cover non-definable actuals, input-dummy forwarding to
  writable dummies, active DO variables, mismatched types/kinds/ranks, malformed
  declarations and invalid inquiry argument types.
- 5 standard-valid but unsupported programs must compile with GNU and be
  rejected by the interpreter. They retain the explicit boundaries for writable
  function arguments, explicit-shape/assumed-size dummies, rank-one LBOUND
  results without DIM and inquiry KIND keywords.

Coverage includes scalar and element OUT/INOUT, undefined values preserved until
read, OUT definition loss on entry and partial return, nested forwarding,
read-only expression snapshots, parenthesized temporaries, direct-binding alias
rejection, disjoint interleaved sections, positive/reverse/dynamic section
strides, frozen actual subscripts and triplets, empty arrays, nonunit and extreme
dummy lower bounds, logical/real32/real64 arrays, numeric and named REAL64 kinds,
array inquiries, PURE subroutines, function array inputs, repeated frames, shared
execution budgets, and the 65,536 total argument-element boundary.

`module_mean_stddev.f90` is a numerical acceptance program using a same-file
module, a REAL64 input array and two scalar OUT results. Independently specified
population statistics are `(mean, stddev) = (5, 2)` for the full sample and
`(5.5, sqrt(4.25))` for a reversed strided sample.

## Nested-section matrix

`run_section_matrix.py` generates 108 additional successful programs. It combines
caller lower bounds `-3, 1, 4`, extents `0, 1, 2, 3, 5, 9`, and outer strides
`-3, -2, -1, 1, 2, 3`, while varying the dummy lower bound and nested section
stride. Each invocation updates a nested sub-section, then the outer section,
then computes a checksum through an array-valued input dummy. Expected arrays,
checksums and extents are calculated independently with Python integer lists.
Both GNU and the interpreter must match them. Every generated source and its
parameters are retained in the result JSON, making failures reproducible.

## Harness and adapter checks

`test_runner.py` contains 12 harness self-tests for numeric tolerances, exact
integer results, finite outputs, token counts, diagnostic requirements, status
codes and stdout leakage. `test/test_argument_frontend.f90` adds an accepted
adapter fixture and 15 independent AST/IR mutations covering dummy intent,
assumed-shape metadata, cached lower bounds, actual rank/definability and inquiry
metadata.

`results.json` and `section-matrix-results.json` record actual tool outcomes,
source expectations and candidate executable hashes. Check their recorded run,
not just this coverage description, when assessing a particular package.
Passing these selected tests does not establish full Fortran conformance or
validation on a platform other than the recorded toolchain.
