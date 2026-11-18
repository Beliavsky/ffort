# Bounded internal READ from a CHARACTER array element

This 0.56 checkpoint extends the input-file position of list-directed internal READ. It reads one complete selected CHARACTER element as one text record, not a section or a concatenation of records.

```fortran
character(16) :: records(2)
integer :: i, value, status
i = 2
records(i) = '71'
read(records(i), *, iostat=status) value
```

UNIT and FMT may be named in that order; optional IOSTAT follows them. The input array must be directly local, nonpointer, default CHARACTER, rank one through three, with fixed CHARACTER length and fixed bounds or allocated storage of fixed CHARACTER length. Nonunit lower bounds are supported. Automatic arrays, deferred-length CHARACTER, dummy/host/use-associated/saved files, components, substrings, sections and whole-array files remain outside this extension.

## Indices and snapshot

Each index is a scalar INTEGER literal, directly local scalar INTEGER name, or supported arithmetic combination (`+`, `-`, `*`, `/`, `**`). Calls, nested array references, noninteger expressions, target-dependent and IOSTAT-dependent indices are excluded. Arithmetic, rank, bounds and representation checks remain enforced. The selected record is evaluated once and copied before conversion. Only the selected element must be defined. Unallocated storage, invalid bounds/shape/length metadata and undefined selected records fail before transfer. A snapshot does not authorize forbidden input/target/status aliases.

## Transfer contract

Ordinary destinations and conversion rules remain those of [scalar internal READ](INTERNAL-READ.md), subject to unchanged alias and ownership checks. No new target sections, element destinations, descriptors, formats or external effects are introduced. Null values, slash termination, repetitions, quoted fields, end-of-record, conversion failures, partial assignment and IOSTAT retain existing behavior. Limits remain unchanged, including the 65,536-character single-record cap, 64 syntactic items, configured expanded-element cap and 16 MiB CHARACTER target budget. Internal conversion does not advance registered external-input cursors.

## Bounded PURE-context exemption

The producer's new PURE local-element exception is narrower than the ordinary transfer contract. Targets must be whole scalar nonallocatable INTEGER, REAL or default CHARACTER objects, with direct writable local storage or permitted OUT/INOUT subroutine dummies. IOSTAT must be a writable scalar INTEGER under the same storage restrictions. Target arrays, allocatables, pointers, derived/LOGICAL/COMPLEX objects, saved or host/use-associated destinations and INTENT(IN) dummies are excluded from this exception. File indices are checked structurally with bounded memoized traversal; calls and cycles cannot pass as pure arithmetic. Existing scalar-PURE context behavior is not generalized by this change.

## Verification status

Focused attempt03 passed all 51 new source contracts (28 GNU executions, 21 compile-only cases, 2 GNU rejections), plus the focused legacy and external regressions recorded in [verification status](VERIFICATION.md). Full clean maintained certification passed; final artifact reconstruction is separately audited.
