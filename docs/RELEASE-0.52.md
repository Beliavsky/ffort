# FortFront 0.52.0: bounded CHARACTER gathering and read-only actuals

The clean maintained verification passed 11,198 source-contract outcomes and 271
native programs. This checkpoint adds two bounded features, not full library
support. The separate fresh reconstructed M_intrinsics survey has 73 ordinary
passes and 2 independently validated cases; these are not added to the maintained
aggregate. See [verification](VERIFICATION.md) for exact identities/categories.

## Two additions

1. **Rank-one default-CHARACTER vector gathering.** A named non-POINTER rank-one
   CHARACTER base and rank-one INTEGER(4/8) vector produce an owned rank-one
   result. Index order, duplicates, base lower bounds, fixed/assumed/deferred
   lengths and padding are retained. Indices are frozen once; bounds and selected
   payload definedness/type/kind/length are checked before copying. Assignment
   and reallocation use the prepared result. Empty results retain descriptor
   metadata; documented fixed LEN/KIND paths do not read undefined values.
2. **Bare gathered read-only actuals.** Supported function and subroutine calls
   accept the unparenthesized gather in an ordinary non-TARGET, non-POINTER,
   non-ALLOCATABLE, non-CLASS assumed-shape INTENT(IN) dummy. Values are copied,
   but backing identity is reserved. Same-base writable siblings reject before
   callee entry/OUT invalidation, even for empty or disjoint selections.
   Parenthesized gathered expressions remain independent snapshots.

The adapter independently verifies written grouping markers and keyword/source
argument mapping, respecting the producer's distinct CALL/function token anchors.
Earlier preview marker failures and their narrow corrections remain chronological
evidence, not rewritten passing runs. No new vendor patch is needed for these
additions; inherited producer repairs remain recorded.

## Boundaries

Existing numeric rank-two row and rank-three single-vector gathers keep their
previous contract. Numeric rank-one gathering, CHARACTER rank-two/three gathering,
POINTER bases, writable scatter and new WHERE/FORALL gather execution are not added.

Direct derived-component values in CHARACTER selectors remain a valid-Fortran
bounded exclusion: checking succeeds, then execution rejects with
`invalid KIND argument opcode`. This is CHARACTER-specific; the numeric
counterpart is not described as unsupported. Ordinary scalar staging is supported.
Dynamic-length untyped constructor nesting also remains excluded; the explicitly
typed counterpart is separately supported.

Existing host/USE, effect, allocation and shape restrictions remain. The 16 MiB
per-frame live gather-cache payload admission limit is released with invalidation,
not a guarantee on all ordinary CHARACTER storage or total heap.

## Original utility progress

Focused selection closures retain original procedure bodies and identify their
wrappers and dependency scope. The CHARACTER forms at 2493 and 2523 no longer block
the working file. The authorized one-byte `nmax` adaptation still stops at 2678:36,
`call set_alloc(ivec(ipos(:nuniq)),jvec)` in `unique_vec_int`, because rank-one
INTEGER gathering is outside this checkpoint. The untouched full source remains
at its 9329:55 configured-cap boundary. Both clean check/run results are source
rejections with empty stdout, not full-program execution. Independent GNU
whole-working-source success does not establish interpreter compatibility.

## Recovered survey and distribution

Original M_intrinsics source identities were recovered exactly. The v4 survey
harness and its new checks were reconstructed; the old harness, 1,110 guards, three
probe bodies and full raw historical streams remain lost. Fresh clean results
are separate from same-raw historical reclassifications and from maintained totals.

Delivery is a compile-ready main ZIP plus a disjoint verification ZIP under the
same root. Extract both into the same parent to obtain complete proof; the
companion does not overwrite main members. Exact archive names, manifests and
external checksum instructions are in [DELIVERY](../DELIVERY.md).
See [CHARACTER gather](CHARACTER-GATHER.md) and
[bare actuals](BARE_CHARACTER_GATHER_ACTUAL.md) for the full contracts. Historical
reports are preserved; Windows execution and full utility-library success are
not claimed.
