# Bounded WHERE assignment

The interpreter supports single-line `WHERE (mask) assignment` and unnamed
constructs containing whole-array or section assignments, zero or more masked
`ELSEWHERE (mask)` arms, an optional final unmasked `ELSEWHERE`, and `END WHERE`
or `ENDWHERE`. Bodies may be empty. WHERE can appear in supported procedures,
IF/DO/SELECT bodies, and as a single-line IF action. Semicolons and continuations
retain their physical source positions.

Masks must be rank-one/rank-two default LOGICAL arrays. Targets and array RHS
expressions must conform in rank and every dimension, not merely total element
count. Scalar RHS expansion, numeric kind conversion, LOGICAL and CHARACTER
assignment, non-unit/negative sections, allocated arrays, automatic arrays,
assumed-shape dummies and module variables compose with existing restrictions.

## Evaluation and safety

- The initial mask is evaluated and frozen before body writes. An ELSEWHERE mask
  is evaluated when that arm is reached, only at positions not selected by any
  earlier arm. Its result is frozen for all assignments in that arm.
- Each selected elemental RHS position is evaluated against the pre-assignment
  target. Values and conversions are staged before any target write. Thus
  overlapping sections and references to other target elements see old data.
  Later assignments in the same arm see earlier assignments' completed values.
- Unselected elemental RHS values are not evaluated, including division by zero
  and uninitialized array elements. A scalar RHS is evaluated once if any mask
  element is active, and not at all for an empty/all-false mask. This includes an
  absent OPTIONAL scalar RHS that is never selected.
- Target availability, section descriptors and array expression shapes are
  still checked for empty/all-false masks. Array allocations and dimension
  conformance do not disappear because no element is selected. Whole allocatable
  targets must already be allocated and conform; WHERE never reallocates them.
- Mask and selected-value evaluation, descriptor work and iteration all share
  the execution budget. Masks and assignment temporaries are bounded by the
  configured 1,000,000-element cap. Initialization flags change only at selected
  destination elements. An error leaves the current assignment uncommitted;
  previous assignments in the construct may already have completed.

Masking applies to elemental evaluation, not the internal work of a
non-elemental array-valued function, transformation or reduction. Such supported
expressions keep their normal evaluation/shape rules. In particular, this does
not promise to mask a function's internal whole-array computations. User
functions in WHERE expressions must be PURE in this bounded subset.

## Explicit boundary

Nested WHERE, WHERE inside FORALL bodies, named WHERE constructs, scalar masks,
scalar/array-element targets, control statements/calls/I/O inside the body,
user-defined assignment and IMPURE user functions are rejected during source
checking. The WHERE implementation remains rank-one/rank-two even if a later
release expands other array facilities. Existing statement identifier
restrictions also reserve WHERE, ELSEWHERE and ENDWHERE.

## Original utilities and remaining gaps

`tests/where/utility_lag_good_data.f90` retains the complete original
`lag_good_data_vec` body; `utility_madev_good.f90` retains complete original
`madev_good` and `lag_good_data_vec` bodies. The checker compares them with
`tests/utilities_slices/source/xutilities.f90`, allowing only normalized newlines.
The new wrappers supply the original kinds, declarations and generic association.
Their small `check_all_equal` dependency is a test assertion helper. The
`moving_average_data_good` helper deliberately implements only the original
NMA=0 branch and rejects other modes. Its default-filling WHERE statement is
also unchanged from the original. This is not verification of the full moving
average routine or the complete utilities program.

The ratio tests demonstrate masking a zero denominator and inspecting only
initialized output elements using PACK. The full original `madev_good` has a
remaining safety limitation: its optional-default MERGE can reference
uninitialized elements that the preceding WHERE intentionally left undefined.
The existing eager MERGE evaluator rejects that case. The dedicated runtime
fixture records this known limit rather than treating GNU output as proof of
well-defined data. Likewise, lagging without a default intentionally leaves
out-of-range output undefined; valid drivers read only positions marked good.
No unrelated MERGE evaluation or initialization semantics were changed.

See `tests/where/README.md` for the differential and corruption test entry points.

## Rank-three composition

WHERE masks and targets remain rank one/two. Rank-reducing sections of ordinary rank-three arrays are supported, including negative third-axis strides. Shape buffers use the three-dimensional representation and runtime purity validation traverses all three scalar indices and triplet operands.
