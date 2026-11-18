# RANDOM_NUMBER in ordinary functions

The bounded interpreter accepts RANDOM_NUMBER in ordinary, unprefixed impure
functions as well as the previously supported main programs, impure subroutines
and IMPURE ELEMENTAL procedures. This includes scalar and intrinsic rank-one,
rank-two and rank-three array function results and local harvests. The six
original utility routines ran_uni_vec, runif_vec, random_logical_vec,
random_logical_matrix, random_logical_3d and random_matrix execute unchanged.
Their only wrapper dependency is dp = kind(0d0).

## Effect boundary

The execution-owned pseudorandom stream is the sole newly permitted effect.
PURE and SIMPLE procedures cannot call RANDOM_NUMBER, directly or through an
impure callee. A malformed SIMPLE designation without its implied PURE bit is
also rejected at runtime. The entire active call stack is checked before a draw.

Ordinary functions still cannot perform external I/O or write module, SAVE or
captured-host storage, directly or through a subroutine. In particular, a shared
variable cannot be a harvest merely because RANDOM_NUMBER itself is now allowed.
Function dummy arguments remain INTENT(IN), and their storage cannot be used as
harvests. Existing alias checks are unchanged. Explicit IMPURE prefixes on
non-elemental procedures remain outside the supported subset. No-argument
RANDOM_SEED is permitted under the same execution-owned effect boundary; see
[RANDOM-SEED.md](RANDOM-SEED.md). RANDOM_SEED SIZE/PUT/GET arguments, RANDOM_INIT,
unspecified kinds and user-shadowed RANDOM_NUMBER remain unsupported.
Impure functions remain invalid specification functions and remain excluded from
WHERE/FORALL expressions.

## Evaluation and resource contract

Each evaluated ordinary scalar impure function occurrence is cached lazily for
one statement evaluation. Broadcasting one scalar call across an array does not
repeat the call per element. Distinct source occurrences and subsequent loop
iterations have independent caches. Array-valued calls already use one result
cache per occurrence. Scalar caches count toward the existing temporary-element
limit. KIND still inspects only type metadata and never runs its argument.
Existing empty-array-expression suppression is preserved. A scalar RHS assigned
to an empty target is still evaluated, unlike an empty array RHS. This is an interpreter
choice, not a promise that another Fortran processor skips the same calls.

Function result identity, type, kind and scalar rank are validated before a
scalar call can perform effects. The configured 1000000-element and 64-active-frame
limits, shared execution budget, target writability/descriptor checks, REAL(4/8)
rounding and first-index-fastest element order remain in force. Recursive calls
share the execution-owned RNG stream; each independent root execution resets it.
No global RNG state or host compiler RNG is used.

Each RANDOM_NUMBER harvest stages its addresses, values and random state before
committing. If that harvest fails, including while evaluating destination
subscripts, its RNG state is restored. This is not transaction rollback for an
entire function: earlier successful statements may already have advanced the
stream. See [the established RNG contract](MEAN-PROGRAMS.md#random_number) for the
documented recurrence and quality limitations.

## Evidence

`tests/random_functions` pins the whole original xutilities.f90 SHA-256 and the
complete byte ranges of all six bodies, including their original CRLF endings.
The caller harnesses test shapes, empty results, REAL ranges, repeated calls,
uniform mean/second moment, optional mean shifts, Bernoulli frequencies and
probability endpoints. GNU Fortran compiles in isolated directories with
`-std=f2018 -pedantic-errors -fcheck=all -O0`. The oracles check invariants and broad
statistical tolerances, never equality between GNU and interpreter RNG streams.
Rank-three checks use supported rank-two slices; rank-three reductions are not
added by this change.

Focused source cases also exercise scalar broadcasting, nested/recursive calls,
PURE/SIMPLE, shared-storage and I/O rejections, invalid harvests, recursion depth,
array size and work limits. `test/test_random_functions.f90` independently checks
adapter/runtime corruption rejection, exact interpreter-only draw accounting,
per-execution reset, rollback of failed harvests and budget failures. Existing
original fixtures remain unchanged. The untouched full utility source still
fails at line 9329's 100000000-element static array; its limits are not raised.
