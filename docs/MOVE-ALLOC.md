# Bounded two-argument MOVE_ALLOC

`CALL MOVE_ALLOC(FROM, TO)` accepts positional or FROM=/TO= keyword arguments.
Both must be distinct whole writable allocatable variables of the same
supported intrinsic type, kind and rank. INTEGER/REAL kinds 4/8, default
LOGICAL/CHARACTER, ranks 1-3 and scalar allocatable CHARACTER are supported.
Ordinary expression, section, pointer, derived-type and mismatched operands
are rejected. Names still resolve to user procedures/generics before the
intrinsic path. Pure local transfers are permitted; existing module and
captured-state effect restrictions remain enforced.

Allocated FROM transfers its owned storage and initialized-element flags to
TO, preserving bounds, shape and CHARACTER length. No array payload is
copied or evaluated. TO's previous allocation is discarded and FROM becomes
unallocated. An unallocated FROM makes TO unallocated. Undefined elements
remain undefined, and scalar CHARACTER definedness follows the transferred
allocation. Empty arrays, zero character lengths, nested allocatable dummies
and repeated executions retain the same lifetime rules.

A nondeferred CHARACTER TO requires equal source length before any change.
Fixed-to-deferred and allocated deferred-to-matching-fixed transfers are
supported. Unallocated deferred FROM with fixed TO is an explicit unsupported
edge; no stale length is inspected. Descriptor identity and overlapping
writable actuals are rejected, including unallocated self-transfer, which is
a deliberately narrower boundary than the standard. Optional MOVE_ALLOC
STAT/ERRMSG controls are not implemented. Existing restrictions on allocatable
TARGET/pointer association remain, so this does not claim pointer-retargeting
semantics for allocations transferred through pointer aliases.

The destination live region is preflighted before either descriptor changes:
the configured array-element cap (one million in the default build), 65,536
characters per element and 16 MiB aggregate CHARACTER payload remain intact.
Both replaced allocations are excluded from the prospective count so an
intra-region move is not double-counted. A rejected cross-region move does
not destroy the old destination. These checks are resource boundaries, not
GNU semantic error oracles.

## Verification

75 focused cases cover all supported kinds/ranks, allocated/unallocated and
empty states, exact bounds, scalar/array fixed/deferred CHARACTER, undefined
flags, module/local and nested-dummy lifetimes, optional presence, user
shadowing, effective aliasing and storage budgets. Candidate results all pass.
GNU checks are 48 successful executions, 13 compile-only boundaries and
11 expected compile rejections; three undefined/absent safety probes are
skipped. Seven retained probes demonstrate the pre-existing ALL(rank3)
boundary, and separate scalar-loop probes verify the rank-three transfer.
The unchanged full M_intrinsics demo_move_alloc executes successfully.
The direct native test performs 346 checks, including 113 malformed
instruction/operand/symbol variants through the public predicate, adapter
and runtime, and repeated fresh-state execution. The runner has 29
adversarial self-tests. GNU and resource/safety-policy results are separate.

Run `python3 tests/move_alloc/test_runner.py`, then
`python3 tests/move_alloc/run_tests.py --candidate EXE --gfortran FC`.
Original source/license hashes and the pinned upstream commit are recorded
in each suite's `upstream.json`. Standards context is F2018 draft
[18-007r1 section 16.9.137](https://j3-fortran.org/doc/year/18/18-007r1.pdf).
The supplied GNU14 compiler lacks MOVE_ALLOC's standardized optional controls;
this release does not expand the interface solely to bypass that oracle gap.
