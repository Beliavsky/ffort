# Release 0.34 composition checks

This suite tests interactions among default-output WRITE and bounded format
groups, ALLOCATABLE-dummy specification inquiries, contextual CHAR naming, and
previously supported functionality. The expected output literals were written
independently before GNU or candidate runs. This is not a claim that the complete
original xutilities module or `filter_matrix_rows` executes in the interpreter.

## Reproduce

```sh
python tests/release034_integration/test_runner.py
python tests/release034_integration/run_tests.py \
  --candidate /path/to/fortfront-interpreter --gfortran gfortran
fpm test --target test_release034_composition
```

The runner copies the selected executable to a private temporary directory,
checks its source/copy/source SHA-256 identity, probes that snapshot's version,
uses only the snapshot for every child invocation, and verifies its final hash.
It rejects empty/nonexecutable snapshots and a concurrent relink during copying.
Each GNU compile and each candidate source run uses a fresh working directory.
The manifest, every selected input and original provenance are checked for
changes during verification. GNU uses Fortran 2018, pedantic errors, and runtime
checks. Only the expected compile-time FORALL obsolescence warning in original
positions wrappers is allowed; other successful compiler diagnostics fail.

## Current coverage

There are 16 candidate cases, all with independently specified check/run exit
statuses, stdout and diagnostic contracts:

- Seven successful candidate/GNU execution comparisons. Four byte-preserved
  utility bodies compose with new inquiries and grouped output; direct PURE
  function CHAR is called from automatic array and CHARACTER specifications;
  saved calls, explicit dummy prefixes and main-program pointer views observe
  frozen entry shapes; deferred CHARACTER reallocation preserves automatic
  shapes/lengths; rank-three inquiries and empty arrays feed grouped output;
  list-directed REAL(8) output also carries an exact INTEGER(8) above 2**53.
- Two successful GNU executions are explicitly candidate source boundaries:
  the unchanged original filter dependency closure and an automatic-local
  pointer-target example. Their GNU output is separately specified and never
  compared to the candidate's required empty rejection output.
- Three GNU compile-only cases cover atomic failure after a completed output
  record, the aggregate frame cap before body output, and unsupported generic
  specification calls. The last originally exposed an unresolved generic
  specific parser bounds crash. It now requires clean source rejection; direct
  named PURE CHAR specification calls remain a positive case.
- Three sources are rejected by both compilers: PURE-to-impure output, an
  OPTIONAL dummy in a specification expression, and scalar CHAR data misused
  as an intrinsic call.
- One unallocated descriptor inquiry is a candidate-only safety probe. GNU is
  deliberately not run, because its allocation requirements are violated.

All CHARACTER output uses exact text including leading, internal and trailing
blanks and record endings. Numeric token comparison is allowed only for the
numeric-only list-directed case; it uses Decimal, exact INTEGER comparison,
finite REAL checks and explicit tolerances. Non-numeric tokens cannot silently
fall through this mode. Failed statements must emit exactly the previously
completed record prefix, never partial output. A host crash/backtrace is never
a successful source/runtime boundary.

The 32 runner self-tests cover these comparison and status policies, GNU-only
oracles, compiler warnings, invalid manifest combinations, original CRLF
preservation, and immutable executable copy races.

## Exact original source provenance

The sole original source is `../utilities_slices/source/xutilities.f90`, SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
All original routine bodies retain CRLF bytes. `original-source-map.json`
records original line ranges and byte offsets, wrapper offsets, per-body
hashes and full wrapper hashes.

`original/positions_module.f90` includes these exact original bodies:

- `positions_char_string`, lines 8812–8821;
- `true_pos_func`, lines 1552–1564;
- `set_alloc_int_vec`, lines 2538–2558;
- `assert_le`, lines 8187–8197.

The wrapper's module and narrowed generic interfaces are synthetic. The driver
calls `positions_char_string` for spaces, case-sensitive misses and repeated
matches, calls the original bounded `set_alloc_int_vec`, and executes both
`assert_le` branches. A synthetic reporting procedure uses an ALLOCATABLE dummy
named CHAR, descriptor-sized automatic INTEGER and CHARACTER locals, SAVE,
grouped internal WRITE, grouped stdout WRITE and format reversion. Exact spaces
inside records are checked. Bare STOP retains its explicit candidate stderr
contract while GNU's stderr is separately checked.

`original/filter_module.f90` includes these exact original bodies:

- `filter_matrix_rows`, lines 8657–8679;
- `true_pos_func`, lines 1552–1564;
- `set_alloc_real_matrix`, lines 2610–2616.

Only the module, dp declaration and narrowed generic interfaces are synthetic;
the dependencies are original bodies, not stand-in implementations. GNU executes
filtering, retaining all rows, an empty filter, invalid column indices and
retaining no rows, checking exact matrix data and extents. Release 0.41's typed empty constructors
remove the final boundary in this unchanged historical driver. The candidate and
GNU now both execute the complete driver and all three original support bodies.
The separate row_gather suite executes all three
original bodies and dependencies with synthetic drivers using declared zero-size
actuals instead of typed empty constructors. No source body or historical driver
is rewritten, and no adapted filter is represented as an unchanged original.

## Native composition

`test/test_release034_composition.f90` is wholly synthetic. It exercises repeated
root execution and SAVE reset, frozen descriptor-based specifications through
reallocation, grouped internal and external output, eight independent metadata
mutations at both frontend and direct-runtime entry, shared-budget failure and
subsequent reset, and the independent source-binding guard against a generic
CHAR call forged as same-result-type intrinsic CHAR. Source-binding forgery is
explicitly an adapter-only test because direct runtime lacks original source.

The final release's empty-cache aggregate is a separate check. See `results.json`
for this focused source run and `verification.json` for its scope and identities.
