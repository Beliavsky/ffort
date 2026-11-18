# Bounded rank-one CHARACTER vector gathering

## Values and descriptors

`strings(indices)` accepts a named, non-POINTER rank-one default-kind CHARACTER
array and one rank-one INTEGER(4/8) vector. It preserves index order, duplicates,
actual base lower bounds and CHARACTER padding. The result is a rank-one value
with the selected element count, not a writable scatter target.

Fixed, assumed and deferred lengths are taken from validated declarations or
runtime descriptors. Selected indices are frozen once, range checked, and only
selected elements are read. Their definedness, CHARACTER tag/kind, string presence
and exact declared length are checked before payload copying. Empty results and
zero-length strings retain their length metadata. Deferred-length data inquiries
still require the appropriate allocated descriptor; fixed LEN and metadata-only
KIND paths need not read index or element values.

Owned selected strings are prepared before assignment/reallocation. Parenthesized
INTENT(IN) snapshots preserve the original utility pattern that subsequently
replaces an aliased allocatable OUT actual. Ordinary allocation, shape, kind,
effect and execution-budget restrictions remain in force.

Gather caches have a 16 MiB aggregate per-frame resident string-payload admission
limit, in addition to existing array element and CHARACTER length limits. A
cache's charge is removed when that cache is invalidated, including implied-DO
refresh. This bounds these gather caches, not total process heap or all ordinary
CHARACTER temporaries.

## User actuals and provenance

A bare gather may associate with a non-TARGET, non-POINTER, non-ALLOCATABLE,
non-CLASS ordinary assumed-shape INTENT(IN) dummy. Both supported subroutine and
function calls use copied selected values, but the bare actual retains its
backing-array identity for conservative alias checks. Any same-base writable
sibling is rejected before callee entry/OUT invalidation, even for disjoint or
empty selections. Existing shared host/USE conflict restrictions also apply.
Parenthesized gathered expressions instead remain independent snapshots.

The adapter independently checks source grouping markers using the producer's
retained tokens and written argument order, reconciled with keyword/formal slots.
CALL nodes and function nodes have different location conventions; the latter
anchor at the closing token and recover the opener by backward balancing.
Strings and comments do not affect delimiter counts. See the complete
[bare-actual contract and preserved correction history](BARE_CHARACTER_GATHER_ACTUAL.md).

## Explicit boundaries

- CHARACTER rank-two/three gathering, POINTER bases, scatter and new WHERE/FORALL
  gather execution are not added. Separate [numeric rank-one](NUMERIC-VECTOR-GATHER.md)
  and [rank-two row/rank-three single-vector](ROW-GATHER.md) contracts do not
  relax these CHARACTER-specific boundaries.
- Dynamic-length untyped constructors containing gathers remain rejected during
  source checking. Use the supported explicitly typed constructor when suitable.
- A direct derived-component value inside a CHARACTER gather selector, such as
  `strings([r%n,1,r%n])`, is valid Fortran but currently checks successfully then
  rejects with `invalid KIND argument opcode`. This is a new CHARACTER metadata
  path limitation, not an inherited numeric-gather restriction. Assign `n=r%n`
  first and use `n` in the vector as the separately tested supported form.
- Bare actuals outside the narrow dummy contract, same-base writable aliases and
  host conflicts are explicit bounded exclusions, not automatically invalid
  Fortran. No global KIND-walker or general alias-analysis expansion is implied.

## Original utilities and current full-file gate

The CHARACTER selection suites preserve exact routine bodies with their stated
raw-CRLF or normalized-line-ending provenance; tailored module/generic wrappers
and drivers are identified. See [gather fixtures](../tests/character_gather/README.md)
and [bare actuals](BARE_CHARACTER_GATHER_ACTUAL.md). These focused closures do not
establish complete original-module support.

The untouched full utility source still rejects at9329:55 under the configured
array-size cap. The authorized one-byte `nmax=10**8` to `10**5` working source now
passed the CHARACTER forms at2493/2523 and stopped at2678:36 in the historical
0.52 checkpoint. The numeric rank-one extension advanced it to2992:1,
unsupported INQUIRE, in the historical 0.53 checkpoint. Bounded
[registered input NAME inquiry](INQUIRE_NAME.md) now advances the focused 0.54
source gate to2995:41, external READ to a CHARACTER array element. Checking and the run command still stop before full-program
interpreted execution. GNU's independent
full working-source run remains a separate observation. No whole-library success,
Windows validation, new standalone survey result or completed release
certification is asserted by this contract document.
