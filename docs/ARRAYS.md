# Arrays (updated for 0.10.0)

This document retains the original array milestones. Its historical exclusions
are not the complete current contract: see [rank three](RANK-THREE.md),
[constructors](CONSTRUCTOR-IMPLIED-DO.md), [bounded numeric gathers](ROW-GATHER.md),
[rank-one numeric gathering](NUMERIC-VECTOR-GATHER.md), and
[rank-one CHARACTER gathering](CHARACTER-GATHER.md). Numeric gathers cover
INTEGER(4/8) or REAL(4/8) rank-one bases, rank-two rows or one vector on any
rank-three axis; CHARACTER gathering remains rank one only. These are read-only
values, not scatter or general vector subscripting.

Array reductions and vector/matrix products added in 0.11.0 are documented in [ARRAY-INTRINSICS.md](ARRAY-INTRINSICS.md).
Rank-one behavior below is preserved. Rank-two explicit-shape arrays, elements,
whole-array operations and assumed-shape dummies are described in
[RANK-TWO-ARRAYS.md](RANK-TWO-ARRAYS.md). Rank-two sections and mixed scalar/triplet selections are supported in 0.10.0;
see [RANK-TWO-SECTIONS.md](RANK-TWO-SECTIONS.md).

## Supported declarations

```fortran
integer :: a(5), b(-2:2), index
real :: fractions(0:3)
logical :: selected(1:4)
integer :: constants(-abs(2):2**2)
integer :: empty(3:1)
```

Constant explicit-shape bounds are scalar INTEGER expressions using the existing
bounded expression subset. Procedure-local automatic arrays added in 0.21 use
the restricted dummy-dependent bounds in [AUTOMATIC-ARRAYS.md](AUTOMATIC-ARRAYS.md). Version 0.3.0 also permits previously defined scalar PARAMETER
constants in these expressions; later releases also support rank-one/rank-two
INTEGER/REAL/LOGICAL and fixed-length CHARACTER array parameters.
`a(5)` means lower bound 1 and upper bound 5. The number of
elements is `max(upper - lower + 1, 0)`. Zero and negative extents therefore
create an empty array without changing the declared endpoints. No access to an
empty array is valid. Bounds must fit the supported signed 32-bit INTEGER range;
intermediate arithmetic is checked too. The aggregate element limit is 1,000,000,
not 1,000,000 per array. Scalars do not count against that element limit.

## Element semantics

```fortran
index = -2
b(index) = 7
fractions(0) = real(b(index)) / 2.0
selected(1) = fractions(0) > 3.0
print *, b(index), fractions(0), selected(1)
```

An element is a scalar of its declared type. Numeric assignment conversions use
the existing runtime's rules, including truncation toward zero for REAL-to-
INTEGER assignment. LOGICAL values can only be assigned to LOGICAL elements.
Each element tracks initialization separately, so writing `a(1)` does not make
`a(2)` readable. Arrays do not alias one another, and execution state is fresh
for every execution call. Array element expressions can be nested inside
subscripts, IF conditions, DO bounds and supported scalar intrinsics.

Subscripts must be scalar INTEGER expressions. The interpreter evaluates index
arithmetic under its existing integer-overflow and work-budget rules, then checks
the result against both declared bounds. Diagnostics identify the offending
array, index and declared range. These are runtime errors (exit status 2), even
when a compiler could diagnose a constant bad index earlier. `--check` validates
types and syntax without executing accesses. A failed assignment leaves its
target unchanged. PRINT still evaluates the complete record before output.

## Whole-array expressions and assignment

```fortran
integer :: a(-1:1), b(4:6)
logical :: selected(3)
a = 2
b = a * 3 + 1
a = b + a(-1)
selected = a > 5
print *, a, selected, max(b, 5)
```

Bare array names denote array values of the declared rank. Unary signs, arithmetic, comparisons,
logical operators, and `abs`, `int`, `real`, `mod`, `min`, `max` are elemental.
Every array operand in an expression must have the same extent. Scalar operands
expand to that extent, including when they appear first in an intrinsic argument
list. Different lower bounds do not change conformance: the first element of one
operand pairs with the first element of the other. A one-element array remains
an array, not a scalar. A scalar or element assignment cannot accept an array.
Array subscripts, IF conditions, DO bounds/steps and declaration constants must
still be scalar. Shape/rank errors are rejected before any program output,
including in unreachable branches.

Whole-array assignment supports a conformable array expression or a scalar
broadcast. It evaluates and converts all right-hand results before committing
any target element. In `a = a + a(1)` each result uses the old `a(1)`, rather than
an element that was just overwritten. Numeric conversions have the same checked
rules as element assignment. A runtime failure stops execution without committing
a partial target. Every broadcast element consumes the execution budget; an
array expression consumes the budget for each evaluated expression node.

A scalar RHS is evaluated once even if the target has zero extent. An array RHS
with zero extent evaluates no elements, including its scalar subexpressions.
These choices define the interpreter's deterministic checked execution policy;
tests involving invalid arithmetic or undefined data are not GNU conformance
claims. Empty arrays with different declared bounds conform to one another.

PRINT expands each array or array expression in element order. It evaluates the
complete expanded record before output, so a bad later element produces no
partial record. Zero-sized array items contribute no values. At most 64 source
items and 65,536 expanded scalar values are allowed in one PRINT statement. The
expanded-value cap is checked at execution; `--check` does not execute PRINT.

## Rank-one sections (0.5.0)

```fortran
integer :: a(-2:4), lo=0, hi=4, step=2
integer :: i
do i=-2,4
    a(i)=i
end do
print *, a(:), a(lo:hi:step), a(4:-2:-1)
a(-1:4)=a(-2:3)           ! Overlap uses a complete snapshot.
a(-2:4:2)=10              ! Scalar expansion into selected elements only.
print *, max(a(-2:4:2),0)
```

`a(lower:upper[:stride])` is rank one, including a one-element or empty section.
Each explicit operand must be a scalar INTEGER expression. The stride defaults
to 1. The first omitted operand defaults to the declared lower bound and the
second to the declared upper bound **regardless of stride sign**. Thus `a(::-1)`
is empty for ordinary ascending bounds; reverse with `a(upper:lower:-1)`.
This follows Fortran 2018 draft N2137, section 9.5.3.3.1, not Python slicing:
https://wg5-fortran.org/N2101-N2150/N2137.pdf . A second colon requires an
explicit stride; `a(::)` and `a(1:3:)` are invalid syntax.

The triplet selects `lower + k*stride` through the last value not past `upper`
in the stride direction. Only selected indices must be in bounds. For an array
`a(5)`, `a(1:6:2)` selects 1,3,5 and is valid; the unselected endpoint 6 is not
an error. An empty triplet selects no data, so its endpoints need not be in
bounds. A zero stride always fails, including in an otherwise empty expression.
Declared zero-sized arrays have no valid selected indices. For `a(5:3)`, `a(:)`
is empty but `a(::-1)` attempts invalid indices and fails a bounds check.
All triplet calculations use checked 32-bit operands and int64 extent/index
arithmetic, avoiding overflow at extreme bounds and strides.

Each section occurrence resolves its triplet once per statement, before any
assignment writes. Dynamic extents are recomputed on each loop iteration.
Every participating rank-one operand must have equal extent, and an array RHS
must conform with the target section or whole array. Type/rank errors and
conflicting known whole-array extents are compile-time errors, including in
unreachable code. Section-dependent conformance, bounds and zero-stride errors
are runtime checks; `--check` intentionally does not execute them.

Whole-array and section expressions share all supported elemental operators
and intrinsics. Only selected elements need initialization. A section target
supports a scalar RHS evaluated once, or a conformable array RHS, and commits
only after every RHS value and conversion succeeds. Overlapping copies,
reversal and self-referential triplet operands therefore see the original data.
Empty array expressions evaluate no data elements, but still validate triplets
and conformability. Scalar expansion evaluates and converts its RHS even for
an empty target, preserving the existing deterministic safety policy.

PRINT expands sections in triplet order and retains atomic output per record,
work limits and the 65,536 expanded-value cap. Vector subscripts and sections
of array-valued expressions remain unsupported.

## Historical array-milestone exclusions

- Rank-three and higher arrays, vector subscripts and constructors.
- Declaration initialization of arrays; DIMENSION, PARAMETER and other attributes.
- Variable bounds outside [the automatic-array subset](AUTOMATIC-ARRAYS.md), assumed shape outside dummy arguments, deferred shape outside numeric allocatable arrays, and pointers. See [ALLOCATABLES.md](ALLOCATABLES.md).
- Array transformational intrinsics and inquiry forms other than scalar SIZE/LBOUND/UBOUND with DIM within the array rank.

Version 0.8.0 adds assumed-shape dummy arrays, writable argument association and
scalar SIZE/LBOUND/UBOUND inquiries. See [ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md).

These are rejected before any program output, including if located in an
unreachable branch. This extension remains a bounded interpreter prototype, not a claim of
complete Fortran array semantics.

## Implementation

The typed IR stores rank and evaluated bounds on symbols, retains their constant
bound-expression trees for independent AST agreement, and uses a distinct element
expression with one scalar subscript. Element assignments carry a target
subscript. Sections retain three optional scalar triplet trees; expressions cache rank and
static extent, or -1 for a section-dependent extent. Runtime descriptors freeze
section starts, strides and extents for each statement. Expressions additionally
cache rank and extent. The adapter derives
those shapes independently from declarations and expression children, checks
conformability and scalar contexts, and rejects forged caches or cyclic trees.
Runtime storage is bounded and separate per symbol, with per-element
initialization flags. The FortFront adapter verifies declarations, bound trees
and cached bound values, the sole INTEGER subscript, and declaration identity.
The pinned frontend's scalar-element rank metadata bug is handled narrowly in
that adapter; see FRONTEND.md. Its mixed-case semantic scope bug has a documented
producer-side correction, retained as a patch rather than hidden source rewriting.

## Examples and verification

- `examples/array_sections.f90`: dynamic strides, overlapping assignment and reversal.
- `examples/whole_arrays.f90`: whole-array broadcasts, expressions and self-reference.
- `examples/array_elements.f90`: mixed types, lower bounds, looping and conversion.
- `examples/array_zero_extent.f90`: constant expressions and an unused empty array.
- `examples/array_bounds_error.f90`: intentional checked execution failure.
- `tests/arrays/`: 179 independent source tests and their GNU comparison evidence.
- `test/test_array_frontend.f90`: 2 matching trees and 11 deliberate disagreements.
- `test/test_runtime.f90`: 53 retained scalar/element/parameter runtime contracts.
- `tests/whole_arrays/`: independent whole-array differential and checked-policy tests.
- `test/test_whole_array_runtime.f90`: direct-IR whole-array runtime contracts.
- `tests/sections/`: independent section corpus and compiler comparisons.
- `test/test_section_frontend.f90`: section-tree, dynamic-cache and target mutations.
- `test/test_section_runtime.f90`: direct-IR section contracts.
- `test/test_array_expression_frontend.f90`: independent shape-cache/context mutations.

Run all verification with `python3 scripts/verify.py` on Linux, or
`python scripts/verify.py` / `powershell -File scripts/verify.ps1` on Windows with
the required tools installed. Only the Linux execution is currently verified.
