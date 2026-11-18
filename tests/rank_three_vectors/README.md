# Rank-three numeric vector-gather contracts (0.50)

Run from the repository root:

    python3 tests/rank_three_vectors/test_runner.py
    python3 tests/rank_three_vectors/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran gfortran

The suite hashes every source and compares successful output byte-for-byte.
Successful checks and stderr must be truly empty. Every negative pins the exact
phase, exit status, source path, line, column and full diagnostic. GNU outcomes
are separate: undefined-data/resource probes are compile-only, and the one
INTENT(OUT) parenthesized-actual constraint violation must be an ordinary compiler
rejection, not a crash. One GNU-valid continued CASE header keeps an independently
specified GNU execution result and a bounded candidate adapter rejection.

## Supported subset

A named non-POINTER INTEGER(4/8) or REAL(4/8) rank-three array may have exactly
one rank-one INTEGER(4/8) vector selector on any axis; every other selector must
be a bare colon. Numeric rank-two gathering remains row-only. The selected axis
has the vector's size; values follow first-axis-fast Fortran element order.
Indices are snapshotted once, then selected values are snapshotted before
assignment/association. Lower bounds, duplicates, direct self-assignment,
allocatable self-reallocation and parenthesized INTENT(IN) actuals are covered.
Only selected values must be initialized. Even when another axis is empty,
indices are checked; an empty vector reads no base elements. KIND validates
metadata without evaluating base or indices. SIZE/SHAPE retain eager gathered
value evaluation. All existing array/cache limits and execution budgets remain.

This is not scatter or general vector indexing. Vector matrix columns,
multiple vectors, scalar/partial/strided other selectors,
LOGICAL/CHARACTER/POINTER bases and writable/unparenthesized direct actuals remain
outside the subset. WHERE/FORALL fixtures may reach earlier retained mask/rank
boundaries; they do not prove a new rank-three masked-execution path. A selector
that reallocates the base is not a validated contract.

## Exact original routines and honest fixture evolution

`provenance.json` records byte-exact CRLF bodies of select_tensor_real,
set_optional_integer and set_alloc_real_tensor. Synthetic module interfaces and
callers are identified separately. Four supported callers test all axes,
default IDIM, duplicate order and repeated empty reallocation. No original body
is rewritten and no full xutilities success is claimed. The authorized full
working source has only the separate nmax digit change. At the 0.50/0.51 numeric
milestone its next parser boundary was rank-one CHARACTER gathering at line2493.
The separate [0.52 CHARACTER extension](../../docs/CHARACTER-GATHER.md) advances
that path; at0.52 the working-source numeric rank-one boundary was2678:36.
The0.53 numeric extension advances that unchanged working source to2992:1 INQUIRE.
Neither extension changes this suite's numeric rank-two/rank-three contract.

All first77 fixture bytes and first failures are retained. Thirty initial
synthetic oracles used unrelated unsupported rank-three RESHAPE/ANY/SUM. Those
sources remain explicit compile boundaries, with separately named `_direct`
scalar-loop oracles covering the intended data semantics. The exact utility
bodies in both generations are identical. Initial77 GNU executions and errors,
subsequent adapter-guard failures, and the original native drafts are preserved
under `initial-evidence/`. No unsupported intrinsic was added to make an oracle
pass.

The original utility CASE arms also exposed a pre-existing producer omission:
`CASE(...); call ...` bodies were discarded. Vendor0110 retains those actions
and their normal statement metadata. Fourteen dedicated CASE fixtures include
DEFAULT, repeated separators, comments/literals containing semicolons, nested
constructs and statements after END SELECT. A continued CASE header still has a
pre-existing physical-location mapping boundary: it is valid GNU Fortran, not
an invalid-source test, and its exact rejection is recorded separately.

The source-free native test validates every axis, producer type/rank, source
identity, empty/KIND metadata, cached-empty unary/binary wrappers, selector
cycles, resource-budget reset, and CASE body/location ownership. Exact counts
and immutable candidate identities are in `verification.json`. Focused tests
are not a substitute for the integrator's final clean whole-release verifier.

## 0.53 numeric rank-one migration

`rank_one_retained.f90` is unchanged. Numeric rank-one parsing now succeeds; SIZE retains the existing eager gather read and fails at5:16 on undefined data. GNU is compile-only, not an undefined-data execution oracle. These measured updates supersede the earlier rank-one rejection boundary; all other suite policies remain unchanged.

## Separate rank-one extension

The [numeric rank-one contract](../../docs/NUMERIC-VECTOR-GATHER.md) adds its own ordinary assumed-shape IN bare policy; rank-two/rank-three direct actuals remain parenthesized. Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed.

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](../../docs/INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
