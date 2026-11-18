# No-argument RANDOM_SEED

`CALL RANDOM_SEED()` and the equivalent `CALL RANDOM_SEED` reset the
execution-owned pseudorandom stream to processor-selected integer state 104729.
This is the same state used at the start of each top-level execution. The next
RANDOM_NUMBER harvest follows the existing Park-Miller recurrence, with unchanged
REAL(4/8) rounding, range and array-element order.

The seed choice is deliberately deterministic, not clock-derived. Fortran leaves
the no-argument seed processor-selected: this contract does not claim GNU's seed
choice or sequence, statistical quality, unpredictability or cryptographic
security. It never changes or queries the host compiler's global RNG.

## Bounded source contract

Only the no-argument intrinsic subroutine is supported. Positional arguments,
SIZE, PUT, GET, unknown keywords and expression-form use are rejected before any
program output. RANDOM_INIT remains unsupported. This feature introduces no
seed-array representation, entropy source, concurrency or global-state API.

Main programs, impure subroutines, ordinary impure functions and IMPURE ELEMENTAL
procedures share one execution-owned stream. A reset in any of these procedures
therefore changes the stream seen by its caller and later sibling calls. PURE,
SIMPLE and implicitly pure ELEMENTAL procedures cannot reset it, directly or
through a callee. Existing external-I/O and shared-storage effect restrictions
are unchanged. Metadata-only inquiries still do not evaluate function bodies.

RANDOM_SEED is not a reserved identifier. Visible user subroutines and module
generics with that spelling use ordinary procedure dispatch, argument association
and purity rules. Data declarations can use the spelling, but then cannot be
called as the intrinsic. The source adapter independently resolves the declaration
and rejects an intrinsic opcode substituted for a source-bound user call.

## Runtime and validation contract

A reset consumes one normal statement step and draws no random values. It
requires the same valid execution-owned RNG state as all other execution; it
cannot repair invalid injected runtime state. Budget, instruction scope,
canonical empty-operand metadata and active-stack PURE/SIMPLE checks precede
any change to the stream. Every operand field, including allocated empty ITEMS
or FORMAT, must be absent/zero for the reset opcode.

The reset commits immediately after validation. Later unrelated failures do not
undo earlier successful statements. The existing RANDOM_NUMBER harvest
transaction remains an exception: if evaluating a harvest destination calls a
function that resets the stream, and that harvest fails, its entry state is
restored with the rest of the harvest transaction.

## Focused evidence

`test/test_random_seed_empty.f90` exercises deterministic scalar/array replay,
nested subroutine and ordinary-function resets, parenthesis-free calls, budget
and invalid-state boundaries, metadata-only rejection at both the adapter and
executor, PURE/SIMPLE caller/callee mutation, unsupported arguments, user-name
shadows and failed-harvest rollback. Repeatability is an interpreter policy test,
not a GNU sequence comparison.

`tests/random_seed_empty` supplies 25 CLI cases with standard GNU syntax/range/
shadow checks separated from deterministic interpreter-policy checks. Its invalid
source probes require rejection before a preceding PRINT sentinel can run.

The existing `tests/mean_programs_independent` no-argument fixture retains its
historical `random_seed_unsupported` filename and unchanged source. Its current
expectation is successful execution printing 991; GNU can independently check
that syntax and output without comparing random streams. Historical release
verification snapshots are retained as historical evidence.
