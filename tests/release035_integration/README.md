# Release 0.35 independent composition

Run from the project root:

```sh
python tests/release035_integration/test_runner.py
python tests/release035_integration/run_tests.py --candidate /absolute/frozen/interpreter --gfortran /absolute/gfortran
```

The parent integration build owns `fpm test --profile debug`. Do not run a second
build while it is active. The runner snapshots and fingerprints the chosen
executable before source checks; GNU compiles separate temporary source files
and is an oracle, never an interpreter backend.

## Coverage and exact expectations

The 19 cases have manually specified output records and GNU stage contracts:
11 executed differential checks, 7 compile-only cases, and 1 invalid PURE source
that both compilers reject. No GNU checks are skipped. Exact comparison retains
CHARACTER spaces, record boundaries and list-directed leading blanks.

- Recursive internal calls mutate live host scalars, arrays and fixed CHARACTER
  storage while grouped WRITE and host SAVE preserve their established semantics.
- A child invokes its recursive defining host, then resumes its own original
  scalar and frozen automatic-array activation. Depth 3 produces 120, depth 1
  produces 20, and depth 0 produces 2: the independently derived recurrence is
  T(d) = T(d-1) + 10*d + 2*(d+1)^2, with T(0) = 2.
- An uncaptured ALLOCATABLE host dummy supplies SIZE at host entry. A child mutates
  only its ordinary frozen work array before and after the descriptor is
  reallocated. Capturing the allocatable itself remains explicitly rejected.
- Scalar host INOUT bounds freeze child array extents and CHARACTER length before
  the child changes the scalar. Zero extents/lengths are included.
- Two unrelated hosts have identically named internal `char` procedures and
  separate child SAVE state. Quoted `char(n)` text and fixed-character substring
  mutation remain distinct from contextual procedure/intrinsic name binding.
- A PURE child reads host state after an IMPURE ELEMENTAL child updates it in
  element order. An impure call from a PURE function is rejected by both tools.
  Ordinary-function transitive host effects remain a documented candidate-only
  boundary, with a precise diagnostic and GNU compile-only evidence.
- A parenthesized actual is a snapshot; direct read-only actual/host overlap is
  conservatively rejected. Array section bounds and live storage are checked.
- Runtime format/type and size failures preserve the exact completed prior
  record and emit none of the failed statement. The list stage still admits a
  65,538-character payload and rejects a record beyond its 16,777,216-character
  limit. Formatted output retains its distinct 65,536-character limit. No limit
  has been increased.

The native `test_release035_composition` independently corrupts twelve metadata
properties, then tests verifier rejection and direct-runtime rejection without
using the verifier as a runtime prerequisite. It also checks repeat roots,
SAVE initializer immutability, shared work-budget cleanup and a forged direct
internal call with no live host. Output corruption targets the first WRITE, so
that test requires no output. The source runtime tests separately verify that
completed earlier records survive a later failed WRITE. This is statement
atomicity, not whole-program output rollback.

## Original-source preservation

`original/quick_sort_module.f90` contains the complete original `quick_sort`,
including `quick_sort_1` and `interchange_sort`: exactly 2,517 bytes and 73 CRLF
lines from xutilities lines 8870–8942. The original whole-file SHA-256 is
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`;
the routine SHA-256 is
`c12792b8b58af0814e11fabc91840133b8f943f306e32ece55cb68cab6529366`.
The module wrapper, `dp` declaration, `isnan` generic/helper and test driver are
synthetic. They are not claimed as original source.

The independent driver checks eight finite values with duplicates, exact sorted
values, full index permutation and value/index association, zero-sized input,
and a repeat call on sorted input. The feature suite has additional size and
ordering cases. Neither suite claims exhaustive NaN handling, arbitrary sizes,
or full original-library execution. The full untouched source still reaches
its next unchanged resource gate in `read_vec_data_unit`; external file READ and
unlisted features remain outside this milestone.

`original-source-map.json` records offsets and fingerprints. The runner pins
both full-source and routine identities, CRLF count, byte length and source
line range; it rechecks source/provenance/executable fingerprints after the run.
`prepare_cases.py` replays all 22 fixture/manifest/provenance files byte-for-byte.
Harness self-tests reject whitespace changes, missing/extra records, host
crashes, timeouts, diagnostic names only in paths, unexpected GNU stderr,
compiler failures, silent differential opt-outs, copy races, changed originals,
and forged wrapper checksums. `verification.json` records an independent exact
comparison of all 6,246 pre-existing Fortran source/native/example fixtures against the
corrected 0.34 ZIP: zero changed or missing. Only this new suite and the new
native target were edited for this assignment.
