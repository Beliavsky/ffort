# Bounded LOGICAL allocatables

LOGICAL joins INTEGER, REAL and CHARACTER in the existing rank-one through rank-three allocatable array path. This is an element-type extension, not a storage-budget increase or a general Fortran ALLOCATE implementation.

## Verified behavior

- Allocation/deallocation and ALLOCATED at ranks one, two and three; nonunit bounds including the third axis; allocated zero-size shapes with preserved nonempty extents.
- Scalar broadcast, whole-array assignment, existing bounded rank-one constructors and rank-two RESHAPE, logical NOT/AND/OR/EQV/NEQV expressions, and rank-reducing section assignment. Same-shape assignment preserves destination bounds, while shape-changing reallocation follows source bounds.
- Recoverable double-allocation STAT preserves the existing descriptor and values. Capacity STAT failure leaves a destination unallocated and successful allocation after releasing the old storage confirms recovery.
- Module allocations persist across procedure calls and reset between fresh executions. Allocatable INTENT(IN), INTENT(OUT), INTENT(INOUT), nested forwarding, OPTIONAL omission versus present-but-unallocated actuals, and allocatable function results retain their established descriptor behavior.
- Incompatible types/ranks, a fixed-array actual for an allocatable dummy, and allocation through INTENT(IN) are rejected. Third-axis bounds failures and undefined/unallocated storage fail before printing a partially evaluated output record.

Rank four, scalar allocatables and nondefault LOGICAL kinds remain unsupported. Existing one-target allocation syntax and storage caps are unchanged. General rank-three reductions are outside scope; plane-wise checks do not imply support for ALL/ANY/COUNT on rank-three arguments.

## Unchanged original utility evidence

The original `xutilities.f90` SHA-256 is `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. The suite extracts, without rewriting, these complete original bodies:

- `set_alloc_logical_vec`, lines 2579–2586.
- `set_alloc_logical_matrix`, lines 2588–2593.
- `set_alloc_logical_tensor`, lines 2595–2600.

`tests/logical_allocatables/extraction-evidence.json` records each body's SHA-256. The test runner validates full-source and body fingerprints plus byte-for-byte inclusion before running any case. The enclosing synthetic program supplies inputs and assertions/output; it does not replace any original function body. It tests the original routines both with unallocated destinations and already allocated INTENT(OUT) destinations, and tests an empty tensor source.

## Independent verification

`tests/logical_allocatables` contains 21 fixtures: 16 GNU oracle comparisons and 5 explicitly skipped GNU cases for interpreter-specific capacity/rank limits and undefined-storage checks. The native `test_logical_allocatables` checks repeated module reset and 16 malformed states at both adapter and runtime boundaries, totaling 32 rejection checks. These include hidden third-axis metadata, malformed allocation/deallocation operand lists, missing/out-of-range expression IDs, incorrect descriptor flags, unsupported element-type or nondefault LOGICAL kind metadata, and a numeric length operand forged onto LOGICAL allocation.

All 21 candidate cases and 16 GNU comparisons passed, alongside 13 runner self-tests and the native 32-rejection test. Expected results are fixed before candidate execution. Every GNU program uses a fresh temporary directory and bounds checking. The runner rejects wrong output, unexpected check output, nonfinite numeric tokens, wrong exit codes, missing required diagnostics and executable changes during the run. Full-source progress is recorded separately; passing the three extracted utilities does not imply that all of `xutilities` is supported.

The isolated LOGICAL extension advanced to the LEN(element) declaration in prepend_char at 3913:26. The integrated 0.30 release also supports that specification expression and optional declaration separators; that release reached TARGET in get_data at 6325:38. Version 0.31 accepted TARGET and rejected POINTER at 6326:16. Version 0.32 adds bounded POINTER views and explicit dummies and now rejects the user-defined choose(n,k) bound at 7967:40. Declaration parsing before body analysis means this advancement does not establish that every earlier utility body works. The full original source remains unsupported.

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).
