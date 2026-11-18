# FORALL verification

Run from the project root:

```sh
python3 tests/forall/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
fpm test --target test_forall
```

The manifest distinguishes `run` (GNU differential), `reject` (source checks,
no output), `runtime` (source accepted, checked execution status 2 and no output),
and `policy` (a documented expected value with independent GNU evidence, not
counted as agreement). Undefined programs are not run through GNU as an oracle.
`results.json` records check mode, execution, compiler and oracle output.

Coverage includes snapshot reversal/transpose, element and section overlap,
frozen masks/bounds, per-statement construct ordering, LHS index-array mapping,
two indices, descending/non-unit/empty ranges, preserved undefined and defined
outer indices, scalar expansion and array results, CHARACTER/LOGICAL/numeric
values, allocatable storage, PURE calls, procedure and IF/DO composition,
continuation/semicolon handling, checked duplicate definitions/undefined data/
shape/bounds/zero stride/resource errors, and the explicit unsupported boundary.

The six utility wrappers preserve the original procedure bodies (newline
normalization only), selected from the source of record under
`../utilities_slices/source/xutilities.f90`. `check_original_bodies.py` verifies
that relationship before the feature suite runs. `diag` is exercised on a matrix
with at least as many columns as rows, so its original result is fully defined.
See `../../docs/FORALL.md` for restrictions and the minimum-int64-stride GNU14.2
policy discrepancy.
