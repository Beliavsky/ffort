# Release 0.32 independent composition checks

All 16 source fixtures here are synthetic. None is an unchanged original utility
body. The `synthetic_get_data_optional` case exercises the supplied utility's
bounded declaration/association pattern, not its external WRITE or implied DO.
Original `fold_bounds` provenance belongs to the separate explicit-dummy suite.

## Scope

Ten success cases compare both the interpreter and GNU Fortran against literal
expected outputs written independently of either implementation. They cover:

- Existing main-program pointers observing explicit-shape TARGET dummy prefix
  copyback, including larger actual tails and declared nonunit lower bounds.
- Same-rank matrix-prefix reshaping in Fortran element order, live row/column
  views, WHERE updates, and FINDLOC/SHAPE composition.
- Reversed strided section copyback without losing the original pointer mapping.
- Shared definition flags through nested assumed-shape and explicit-shape calls,
  partially assigned OUT prefixes, preserved defined tails and later alias writes.
- Caller-backed assumed-shape TARGET export through POINTER INTENT(OUT), nested
  forwarding, repeated frame reuse and distinct aliases of the same backing.
- Present disassociated versus absent OPTIONAL pointer descriptors, NULLIFY and
  associated empty views.
- Recursive functions with shrinking explicit-shape input prefixes, INTEGER and
  REAL kinds 4/8, and empty OUT-prefix association preserving caller storage.

Three candidate runtime-policy cases require a clean check, execution exit 2,
no stdout and the intended diagnostic: an undefined OUT-prefix element, escaping
callee-local storage, and an operation on an absent OPTIONAL pointer. GNU only
compiles these cases; undefined or policy-excluded executions are never treated
as semantic GNU oracles.

Three standard-valid bounded exclusions require check/run exit 1 and the stated
source diagnostic. GNU only compiles them: view escape from a runtime-bound
explicit-shape TARGET dummy, a POINTER actual passed to an ordinary explicit-shape
dummy, and a procedure reading pointer data even in an uncalled body. Ordinary
explicit-shape TARGET copyback and assumed-shape TARGET pointer escape have
separate passing execution cases. No broader pointer admission is inferred.

## Runner

From the repository root:

```
python3 tests/release032_integration/test_runner.py
python3 tests/release032_integration/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

GNU flags are `-std=f2018 -pedantic-errors -fcheck=all,no-array-temps -O0`.
Only the expected noncontiguous actual's array-temporary warning is disabled;
bounds and other runtime checks remain enabled. All remaining execution stderr
fails the oracle. Every program compiles in a fresh temporary directory.

The runner uses a hashed private candidate snapshot, exact integer comparisons,
finite-real comparisons and strict success/check/rejection/runtime exit codes.
It rejects unexpected stdout, missing diagnostics, crashes and timeouts, and
checks source, manifest and candidate integrity. Sixteen runner self-tests
exercise these assessment rules. Compile-only cases are reported separately from
actual differential executions.

## Independent native composition

`test/test_release032_composition.f90` exports an assumed-shape TARGET view, then
passes that OPTIONAL POINTER alongside an ordinary runtime-bound explicit-shape
TARGET dummy. It checks live prefix updates, caller tails, FINDLOC and SHAPE,
then tests 16 corruptions independently through the source adapter and direct
runtime: 32 rejections. Every mutation begins with a freshly parsed, independently
validated and successfully executed baseline. Three further repeated executions
check fresh state. A separate native runtime-policy probe verifies that an
undefined unused actual tail remains undefined after explicit OUT-prefix copyback.

The initial merged runtime incorrectly entered deferred-shape POINTER dummies in
its explicit-bound freezing pass. The success cases exposed both OPTIONAL and
nonoptional forms before implementation repair. The corrected build passes all
16 source cases; `results.json` and `verification.json` record final evidence.
