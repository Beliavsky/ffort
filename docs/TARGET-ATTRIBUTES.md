# TARGET declaration milestone (historical 0.31 checkpoint)

Historical checkpoint: the later [POINTER views extension](POINTER-VIEWS.md) adds
bounded backed views and lifetime tracking. The boundary and candidate hash below
record the TARGET-only checkpoint, not the current complete feature set.

This milestone preserves the `TARGET` attribute in the interpreter IR and checks it
against FortFront declaration metadata. It supports the interpreter's existing
intrinsic scalar and rank-one through rank-three declarations, including module
variables, procedure locals, explicit-INTENT dummy arguments, OPTIONAL arguments,
and supported ALLOCATABLE arrays. TARGET does not change ordinary value assignment,
allocation, argument copy-in/copy-out, or execution-reset semantics.

The independent adapter must reject both missing and fabricated TARGET metadata.
The runtime must reject impossible TARGET/PARAMETER combinations independently of
the adapter. A legal ordinary variable with TARGET metadata is not itself an error
at the raw runtime boundary: that boundary has no source with which to prove that a
legal attribute was present or absent.

## Explicit boundary

This is **not pointer support**. POINTER declarations and pointer association are
still rejected. There is no pointer descriptor, target lifetime tracking, returned
alias, dangling-association detection, or pointer-aware actual/dummy argument
association. In particular, the original `get_data` subroutine in xutilities has not
been made executable by this change. Supporting its returned pointer requires an
explicit storage/lifetime/alias model rather than merely dropping TARGET or
copying the selected data.

The original `tests/utilities_slices/source/xutilities.f90` is immutable and must
retain SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.

## Verification

`tests/target_attributes/manifest.json` contains independent source fixtures:

- Scalar INTEGER/default and kind 8, REAL/default and kind 8, LOGICAL, CHARACTER.
- Each intrinsic type at ranks one, two, and three.
- Grouped declarations, both TARGET/DIMENSION attribute orders, module and local
  storage, ordinary value semantics, and allocations with nonunit lower bounds.
- TARGET dummies with IN/OUT/INOUT and OPTIONAL, including a non-TARGET actual.
- ALLOCATABLE+TARGET lifecycle and descriptor dummies.
- Invalid PARAMETER+TARGET in both attribute orders, repeated TARGET, invalid
  pointer association, and a standard-conforming POINTER declaration which remains
  outside the interpreter subset.

GNU Fortran is only an independent oracle, never an interpreter execution backend.
The runner compiles each oracle in a fresh temporary directory and checks normal
output or rejection. It separately checks interpreter `--check` and execution exit
codes, rejects stdout leaks for negative cases, and records source and candidate
hashes. `gnu-results.json` records oracle results; `results.json` records candidate
verification when run. These filenames do not by themselves imply a passing run.

`test/test_target_attributes.f90` checks repeated execution and independent
adapter/runtime mutation rejection. Its output is captured in `native-results.txt`
when executed. The full repository suite remains a separate regression check.

Example invocation from the repository root:

```
python3 tests/target_attributes/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
fpm test --profile debug --target test_target_attributes
```

Verified in this milestone: all 15 source cases pass the candidate checks and GNU
oracle checks (10 executions, four GNU compile rejections, one compilation-only
POINTER fixture). The native debug test passes eight adapter metadata mutations,
one PARAMETER/TARGET runtime mutation, and three repeated source executions.
All 13 runner self-tests pass. The candidate binary SHA-256 before and after the
source suite was
`3da1a263a9ca52c9086696a46c934b19c1f0fbcf16cf7e5c1a7e89a1010ca35c`.
The unchanged-original hash check is recorded in
`tests/target_attributes/original-source-check.json`.

The unchanged full source now passes the TARGET declaration at 6325:38 and stops
at the following POINTER attribute at 6326:16 with
`Unsupported declaration attribute`. This is declaration progress, not an
execution claim for the routine.

The integrated 0.32 release adds bounded POINTER views and explicit-shape dummies;
its 0.32 unchanged-source boundary was choose(n,k) at 7967:40. The 6326 receipt
above records the earlier declaration-only checkpoint.

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).
