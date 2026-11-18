# Bounded FORALL statements and constructs

The interpreter accepts one or two INTEGER(4/8) index specifications in a FORALL
statement or an unnamed FORALL construct:

```fortran
integer :: i, j, a(3,3)
a = reshape([1,2,3,4,5,6,7,8,9],[3,3])
forall (i=1:3,j=1:3,i/=j) a(i,j) = a(j,i)
```

Each index must have an explicitly declared, local, non-dummy INTEGER variable
of supported kind. Its value and defined/undefined state outside the construct
are preserved. Reusing an active DO control variable is rejected. Header bounds
and optional strides must be scalar INTEGER expressions and may not refer to
any index in the same header. They are evaluated once on entry. Bounds and
strides must be representable in the corresponding index kind; zero strides are
checked execution errors. Positive and negative strides, non-unit lower bounds,
zero-trip ranges, and two-index Cartesian products are supported.

The optional mask is scalar LOGICAL. The mask is evaluated for every index tuple
on entry, before any body assignment, and those Boolean values remain fixed for
the entire construct. With an empty tuple set or a false mask, the corresponding
assignment target and RHS are not evaluated.

## Simultaneous semantics

A construct body consists only of intrinsic assignments to array elements or
sections. Targets may be supported INTEGER, REAL, LOGICAL, or fixed-length
CHARACTER arrays, including array dummies and already allocated arrays. Allocated
CHARACTER arrays may use fixed, assumed or deferred length descriptors; FORALL
fits each element to its current length and does not change that descriptor. Rank-one
and rank-two sections, scalar expansion, conforming array expressions, PURE
functions, array-valued results, and supported intrinsics compose with FORALL.

For each assignment statement:

1. Every selected iteration computes its destination subscripts/section and RHS
   from the state before that statement.
2. Converted values and their exact destination offsets are buffered.
3. Only after all evaluations succeed are those values committed.
4. The next statement then begins across all selected iterations.

For example, `forall(i=1:n) a(i)=a(n+1-i)` reverses the array, and two-index
`a(i,j)=a(j,i)` transposes it. Neither is executed as a sequential DO loop. Array
sections and array-valued index mappings receive the same snapshot treatment.
A mask that reads an array changed in the body is not recomputed.

Multiple definitions of the same array element by different iterations of one
assignment are invalid Fortran. The runtime detects duplicate offsets, including
overlaps between sections, and rejects the statement before committing it. The
same element may be assigned by different body statements, as Fortran allows.
Existing undefined-value, shape, bounds, arithmetic, character-fitting and
execution-budget checks remain active. Earlier completed body statements are
not rolled back if a later statement fails.

## Limits and explicit exclusions

- At most two index specifications, each producing at most `max_array_elements`
  values, and at most `max_array_elements` tuples in their product (1,000,000 by
  default). The normal execution budget applies during enumeration, mask
  evaluation, expression validation, and buffered assignment.
- The temporary is bounded by the target array size. Duplicate destinations
  cannot grow a larger buffer. Array storage continues to use existing limits.
- Nested FORALL, WHERE, named constructs, typed headers, pointer assignment,
  whole-array targets, scalar targets, module/dummy/PARAMETER index variables,
  and dependent bounds within the same header are outside this implementation.
- All referenced user functions must be PURE, including those in bounds,
  subscripts and masks. No impure-call evaluation order is promised.
- A single-line IF can contain a FORALL statement, but not a FORALL construct.
  FORALL constructs can appear inside supported IF/DO/SELECT bodies and in
  functions/subroutines.
- Allocatable targets are elements/sections of existing allocations. FORALL does
  not allocate or reallocate the target.

FORALL is an obsolescent Fortran 2018 feature. This bounded implementation does
not add DO CONCURRENT or parallel execution.

## Verification and GNU edge case

`tests/forall/run_tests.py` separates GNU differential successes, syntax-boundary
rejections, checked runtime errors, and an explicit interpreter-policy case.
`test/test_forall.f90` checks the independent AST adapter and malformed-IR runtime
boundary. The six `utility_*.f90` wrappers contain unchanged original procedure
text from `tests/utilities_slices/source/xutilities.f90`, apart from newline
normalization: `matrix_by_vector_real`, `repeat_int`, `repeat_real`,
`sign_changes_real`, `ivec`, and `diag`. These focused wrappers are not evidence
that the whole utilities module is supported.

`minimum_stride.f90` deliberately exercises the two representable indices
0 and -9223372036854775808 with the latter as the stride. GNU Fortran 14.2.0
produces zero iterations for this case. The interpreter enumerates the two
indices without computing an overflowing trip-count expression and produces
`7 7`. The suite preserves GNU's compiler/run evidence but checks this case
against the documented interpreter result, not against GNU agreement. No
terminal increment is evaluated, including at either INTEGER(8) endpoint.
