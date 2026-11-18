# Allocatable assignment and function results

Rank-one/rank-two/rank-three INTEGER(4/8), REAL(4/8) and default LOGICAL allocatable arrays support intrinsic
whole-array assignment. An array-valued RHS allocates an unallocated target and
reallocates an allocated target when any dimension extent changes. A conformable
allocated target keeps its existing bounds. Scalar expansion requires an already
allocated target; assignment to an array section never reallocates its parent.

When a fresh allocation is needed, an unparenthesized whole-array variable RHS
supplies its lower bounds. Parenthesized arrays, sections, constructors and array
function expressions have lower bounds of one. A zero-extent dimension also has
lower bound one and upper bound zero. Equal total element counts do not imply
conformability: reshaping from 2-by-3 to 3-by-2 reallocates the target.

```fortran
integer, allocatable :: a(:)
a = [1,2]
a = [a,3]       ! Complete old RHS is read before replacement.
a = a(2:)       ! Reallocates to two elements, lower bound one.
```

All RHS elements are evaluated and converted into temporary storage before any
target values, definition flags, allocation status or bounds are replaced. This
supports overlapping self-assignment and avoids a partially changed target on a
failed conversion or undefined read. New storage is counted against the same
1,000,000-element pool as explicit ALLOCATE: one per local frame and one shared
by module data. Replacement excludes the old target from its new pool count.
Statement temporaries and function-result caches retain their separate existing
bounded policies. Allocation and shape validation never makes undefined elements
readable.

Ordinary numeric and LOGICAL array functions may declare an allocatable deferred-shape result.
The result starts unallocated on each invocation and must be allocated before
return, including when its size is zero. Nonempty results must have all elements
defined. The result may be filled by explicit allocation plus assignment, or by
allocatable intrinsic assignment. It uses the existing ownership transfer and
per-statement caching documented in [ARRAY-RESULTS.md](ARRAY-RESULTS.md). A function
result's internal lower bounds are not the bounds of its external expression.

```fortran
function first_three() result(a)
    integer, allocatable :: a(:)
    a = [1,2,3]
end function
```

The interpreter explicitly enables a narrow default-off FortFront frontend option
for this standard assignment behavior. The rest of strict-mode declaration and
semantic checks remain enabled. This is not a fallback to inference mode.

## Checks

Run `python tests/allocatable_assignment/run_tests.py --candidate PATH --gfortran PATH`.
The 26 focused cases include 19 executed GNU comparisons and seven interpreter-only
undefined-read, allocation-state and resource-limit checks. Native
`test_allocatable_reallocation_option` verifies the option's unchanged default,
explicit opt-in, and continued IMPLICIT NONE rejection.

The rank-three extension adds bounds, zero-extent, reallocation and function-result
checks in [RANK-THREE-ALLOCATABLES.md](RANK-THREE-ALLOCATABLES.md).
