# Runtime explicit-shape dummy bounds

This bounded source extension adds nonoptional explicit-shape dummy arrays of
rank one, two and three. Supported element types are INTEGER kinds 4/8, REAL
kinds 4/8, LOGICAL and default CHARACTER, including fixed and assumed element
lengths under the existing CHARACTER association rules. Explicit INTENT remains
required. Existing procedure purity and function restrictions still apply.

```fortran
subroutine fill(x, n)
  integer, intent(inout) :: n
  integer, intent(out) :: x(-1:n-2)
  integer :: scratch(size(x))
  n = n + 1
  scratch = 7
  x = scratch
end subroutine
```

All scalar actuals are associated before dummy bounds are evaluated, regardless
of dummy-list order or keyword-actual order. Bounds are frozen once at entry;
changing `n` above does not resize `x` or `scratch`. Each invocation receives fresh
storage and definition flags. Local automatic arrays and function results may
use supported descriptor inquiries such as `SIZE` of the now-associated explicit
dummy, including an undefined INTENT(OUT) dummy.

## Specification subset

Bounds must be scalar INTEGER constants or expressions over nonoptional scalar
INTEGER INTENT(IN/INOUT) dummies and INTEGER parameters. Unary signs, `+`, `-`,
`*`, `/`, `**`, ABS, MIN, MAX, MOD and MODULO use the existing checked evaluator.
Dependencies must satisfy the existing declaration-order rules. Dynamic dummy
bounds do not use array inquiries, array elements/sections, value-dependent
reductions, local variables, OPTIONAL dummies or INTENT(OUT) scalar values.
General specification functions are not added.

Every explicit dimension must have an upper bound; the lower bound defaults to
one. Zero or negative extents become empty dimensions with normal inquiry bounds
1:0. Nonempty dimensions retain their declared bounds even when another dimension
is empty. The runtime validates every dimension before computing the product, so
an empty dimension does not hide an overflowing bound or an unrepresentable
extent. Each bound and extent must fit the supported default INTEGER index range.

## Association and copyback

The actual must have the same element type, kind and rank as the dummy. Different
shapes are allowed for same-rank explicit-shape association when the actual has
at least as many elements as the dummy. The dummy uses the first required elements
in Fortran element order, with its own declared shape and lower bounds. This is a
bounded subset of Fortran sequence association: cross-rank association and scalar
actuals for array dummies remain unsupported.

Whole arrays and supported triplet sections can supply explicit dummies. Input
array expressions are also allowed. Writable actuals use the existing frozen
caller bindings, including reversed/strided sections and nested forwarding.
Only the associated prefix is invalidated on INTENT(OUT) entry or copied back on
normal return. A larger actual's unused tail keeps its values and definition
flags. An unassigned OUT element remains undefined; IN/INOUT preserve incoming
flags without reading every element. Reading an undefined selected element fails.

The existing conservative writable-alias policy remains in force. Do not assume
that truncating an explicit dummy's view relaxes overlap checks on direct actual
bindings. A shorter actual is rejected at call entry before the body runs.
Known fixed CHARACTER length mismatches are rejected before execution; an
assumed-length forwarding dummy defers this check to entry-time association.
CHARACTER association retains its fixed/assumed-length checks; this
extension does not introduce character-storage sequence association.

## Boundaries and resource safety

OPTIONAL explicit-shape dummies, assumed-size arrays, mixed explicit/assumed
shapes, dynamic lower bounds on assumed-shape dummies, POINTERs and unsupported
specification dependencies fail closed. Allocatable dummies retain their separate
existing descriptor contract. Explicit bounds do not relax executable subscript,
kind, character-length, initialization, aliasing or purity checks.

Dummy and local storage share the configured 1,000,000-element frame limit. Bound
arithmetic, actual materialization and copies consume the existing shared work
budget. Arithmetic overflow, division by zero, excessive bounds/extents, a too-
short actual or an over-limit frame fail safely before the procedure body. The
64-frame call-depth rule and explicit RECURSIVE requirements are unchanged.
This is an element/frame policy, not a process-wide heap or byte limit.

## Verification and provenance

`tests/explicit_dummy_bounds/run_tests.py` has 57 focused source cases with
independent expected output and strict GNU Fortran comparison. It runs 31 safe
GNU programs, compiles 21 safety/boundary programs without executing them, and
requires five GNU compile rejections. Candidate checks require the correct
check/run exit status, meaningful diagnostics and no stdout on rejection. The
runner self-tests are included in `scripts/verify.py` alongside the source suite.

The corpus covers ranks one through three, kinds and CHARACTER lengths, entry
ordering/freezing, zero/negative extents, repeated/recursive/nested calls,
SIZE-dependent locals/results, prefix reshaping, writable sections, actual tails,
definition flags, checked arithmetic, exact/over resource limits and unsupported
boundaries. `original_fold_bounds.f90` embeds the supplied utility's unchanged
`fold_bounds` and recursive `group_sizes` bodies with original CRLF bytes.
Full-source and body SHA-256 checks run before every test invocation. The new
wrapper exercises multiple invocations, extra output elements, empty calls and
recursive group partitioning; it does not establish full-module support.

The native suite independently rejects 23 malformed declarations/expression
mutations at both adapter and runtime entry (46 checks). Eight producer checks
verify CHARACTER length metadata separately. Vendor patch 0055 preserves literal
and default lengths, resolves actual designators by scoped declaration, and
leaves unresolved lengths to runtime storage checks. Five prior known-length
mismatch fixtures now reject during checking; their source bytes are unchanged.
The former explicit-shape rejection fixture now executes against GNU.

This remains a source-only extension on frozen 0.31. Release versions and release
gates are not changed by this feature.
