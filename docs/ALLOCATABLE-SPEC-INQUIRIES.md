# Allocatable dummy specification inquiries

Automatic local array bounds and supported runtime CHARACTER lengths may now use
SIZE, scalar-DIM LBOUND, or scalar-DIM UBOUND of a mandatory ALLOCATABLE dummy with
INTENT(IN) or INTENT(INOUT), at ranks one through three. The existing INTEGER,
REAL, LOGICAL and CHARACTER allocatable types are covered. This includes deferred
CHARACTER length and numeric kinds already supported by the interpreter.

The change is in specification-expression eligibility only. The runtime already
associates and validates dummy descriptors before evaluating local specification
expressions. Inquiries read shape/bounds, not array elements: allocated arrays
with undefined element values are valid inputs. An unallocated actual produces a
checked runtime error before the procedure body runs. Zero extents are valid.
Automatic extents and CHARACTER lengths are frozen for the invocation; subsequent
deallocation, reallocation, allocation-changing assignment, or input mutation do
not resize the local object.

Existing expression nesting, arithmetic/index checks, call/step budgets and the
1000000-element frame limit remain configured. Dummy storage and automatic locals
still share that frame cap. Eligible inquiries may compose with already supported
arithmetic and bounded PURE specification calls. No user-defined constant
expression or new value-based array reduction is introduced.

## Deliberate boundaries

- ALLOCATABLE INTENT(OUT) is excluded because it enters unallocated.
- OPTIONAL dummies, pointer inquiries in procedure specification expressions,
  and inquiries of ordinary local or mutable module allocatables are excluded.
- Array sections and general array value expressions are not newly admitted.
- Explicit-shape dummy bounds retain their separate scalar-dependency restriction.
- This extension does not add general allocation-dependent shape inference or
  defer local allocation until a later body statement.

## Original utilities evidence

The immutable xutilities source retains SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
The automatic `xmask(size(xx,1))` declaration at line 8663 is now admitted. The
isolated feature's next complete-file diagnostic is **8812:39: Expected a
nonreserved name**, at the `char` dummy in `positions_char_string`. Combined
0.34 also supports that contextual name and reaches unsupported nested
quick_sort procedures at 8926:16.

`original_filter_matrix_rows_gnu.f90` embeds the complete original routine's
bytes, lines 8657–8679, with synthetic support helpers and a driver. GNU executes
filtering, all/none retained rows, invalid columns and an empty filter. Candidate
rejection remains explicit. The isolated inquiry checkpoint lacked external
WRITE; combined 0.34 supports it and reaches the unsupported vector gather
`xx(true_pos(xmask),:)`. Neither checkpoint claims complete original execution.

`original_filter_predicate_fragments.f90` retains original declaration and mask
loop fragments in a synthetic helper. GNU executes it, but the candidate exposes
a separate producer location mismatch on its continued single-line IF. This is
recorded as a boundary, not hidden as successful execution.

`adapted_filter_predicate.f90` executes the retained declarations and predicate
assignment with that conditional changed to an equivalent block IF. It omits the
independent I/O and final vector gather and checks the expected mask against GNU.
It is explicitly an adapted helper, not the unchanged original routine.

`original-source-map.json` records byte offsets, line spans and SHA-256 hashes.
Every focused run verifies the full source and each retained fragment before
executing a test. GNU reference stdout and candidate rejection stdout are checked
separately when the source is a current interpreter boundary.

## Verification

The focused suite contains 37 cases, including ranks one through three, both
eligible intents, lower bounds, zero extents, undefined elements, frozen shapes,
deferred CHARACTER, function results, nested/repeated calls, bounded PURE call
composition, caps, unallocated entry and source boundaries. GNU independently
checks 33 cases; four unallocated-input safety probes deliberately skip GNU
execution because the input violates its allocation requirements.

The native `test_allocatable_spec_inquiries` passes 356 checks: source/adapter
and runtime positives, repeated invocations, empty-output unallocated failures,
and malformed-IR eligibility/adapter/runtime rejections. All 137 native programs
pass in this isolated 0.33-based tree. The runner has 15 self-tests, including
provenance validation and separation of GNU-only output from candidate output.
Full release regression verification remains a separate check.
