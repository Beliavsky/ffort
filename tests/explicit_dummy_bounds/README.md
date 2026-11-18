# Runtime explicit-shape dummy bounds

Run:

```sh
python tests/explicit_dummy_bounds/test_runner.py
python tests/explicit_dummy_bounds/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The 57 source cases independently compare interpreter check/run outcomes and
GNU Fortran output with hand-written expected results. GNU uses
`-std=f2018 -pedantic-errors -fcheck=all -O0` in isolated temporary directories.
There are 31 safe GNU executions, 21 compile-only cases and five required GNU
compile rejections. Undefined reads, short actuals, arithmetic failures, aliasing
and interpreter resource policies are **never executed by GNU**. The runner
rejects manifest configurations that would execute an unsafe case, requires exact
candidate exit codes and diagnostics, and rejects every byte of stdout from
rejection fixtures. Its self-tests verify these protections.

Coverage includes constant/runtime bounds, default/wide numeric kinds, LOGICAL,
fixed/assumed-length CHARACTER, ranks one through three, lower bounds, empty and
negative extents, reordered keyword association, repeated calls, frozen INOUT
bounds, SIZE-dependent locals/results, recursion, and explicit-to-assumed-to-
explicit forwarding. Association probes cover differently shaped same-rank
actuals, array expression inputs, reversed/strided sections, element-order prefix
copyback, preserved larger-actual tails and per-element definition flags. Safety
cases cover scalar/array undefined reads, short actuals, overflow/division by zero,
index/extent ranges, exact/over frame limits and conservative alias rejection.
Boundary cases fail closed for OPTIONAL explicit dummies, assumed-size/mixed
shapes, dynamic assumed-shape lower bounds, unsupported specification dependencies
and the deliberately narrower same-rank policy.

`original_fold_bounds.f90` contains byte-exact original `fold_bounds` and recursive
`group_sizes` bodies from the supplied `xutilities.f90`, including their original
CRLF line endings and comments. `provenance.json` records full-source and body
hashes/lengths. Every runner invocation checks the source and both embedded slices.
The wrapper/caller is new and does not establish full utilities-module support.

This is source-only work atop frozen 0.31. It changes no release version or
release gate. See `docs/EXPLICIT-DUMMY-BOUNDS.md` for the bounded contract.
