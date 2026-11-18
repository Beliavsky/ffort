# Release 0.56.0 scope and measured verification

## New bounded behavior

`read(records(i), *, iostat=status) value` may use one complete local default-CHARACTER rank-one, rank-two or rank-three array element as its internal input record. The array has fixed CHARACTER length and fixed bounds, or is an allocated array with fixed CHARACTER length. See [the full contract](INTERNAL-READ-ELEMENT.md).

Indices are bounded local scalar INTEGER literal/name/arithmetic expressions. The input is evaluated and snapshotted once before transfer; this does not permit aliasing or target/IOSTAT-dependent file indices. Producer UNIT/control spelling is bound to original tokens and its structural AST is bound to the IR, not merely the base name. Runtime descriptor, bounds, allocation, selected-record definedness and storage consistency remain checked.

The PURE producer exemption is deliberately narrower than ordinary internal READ: direct local CHARACTER file elements, effect-free INTEGER indices, whole scalar nonallocatable intrinsic INTEGER/REAL/CHARACTER destinations and INTEGER IOSTAT, with verified writable local storage or permitted OUT/INOUT subroutine dummies. Host/use, saved, pointer and INTENT(IN) destinations are excluded. It does not enable external I/O in PURE procedures.

## Preserved boundaries

No automatic/deferred-length/dummy/host-associated/saved input arrays; no pointer/component/section/substring/whole-array input files; no user-call or nested array indices; no new formats, target-section support, file opening or cursor effects. Legacy scalar internal READ and external READ policies are not widened generally. Existing limits and error/partial-transfer semantics remain in force.

## Evidence and status

The development attempt03 focused checks passed: 51 new internal-file-element source contracts, 67 external-READ-element contracts and 81 legacy internal-READ contracts. New native checks reported 106 IR, 37 frontend and 24 producer-PURE assertions; unchanged legacy native checks reported 224 internal-READ and 447 external-element assertions. Both new READ harnesses passed 30 tests in normal mode and 30 in optimized mode each. These are focused development results, not a full maintained-suite certification or a count of distinct programs.

The reduced utilities working copy now stops at 3084:47 on an internal READ with a section target. The untouched original remains blocked at 9329:55 by the array-size cap. Neither full utilities source is claimed to execute successfully.

Full clean maintained certification passed as recorded below. Final archive identity and reconstruction remain separately audited delivery gates. Historical [0.55 release notes](RELEASE-0.55.md) are unchanged.

## Measured clean run

The fresh-source, empty-cache Linux GNU Fortran 14.2 debug maintained run passed 11,625 source contracts across 201 suites: 10,865 direct GNU checks, 83 lowered SIMPLE checks and 677 GNU skips, with zero failed contracts. It passed 285 native programs and 397 verifier commands, with 7 separately reported static/shared comparisons and 2,885 unittest-method executions. Direct GNU checks include execution, compile-only and required rejections; they do not imply universal execution equality.

See [measured summary](verification/0.56.0/final-summary.json), [source/output audit](verification/0.56.0/source-audit.json) and [tool preflight](verification/0.56.0/clean-preflight.json).
