# Rank-two sections (0.10.0)

Array reductions and vector/matrix products added in 0.11.0 are documented in [ARRAY-INTRINSICS.md](ARRAY-INTRINSICS.md).
## Supported designators

For a rank-two INTEGER, REAL(kind=4/8) or LOGICAL array, each subscript may
independently be a scalar INTEGER expression or a triplet `lower:upper:stride`.
Exactly two subscripts are required. A scalar removes its dimension; a triplet
preserves it. Thus `a(:,j)` and `a(i,:)` have rank one, `a(:,:)` has rank two,
and `a(i,j)` is scalar. These scalar/triplet section rules are separate from
the later read-only numeric `matrix(rows,:)` gather. Rank-two vector columns
remain unsupported; see [ROW-GATHER.md](ROW-GATHER.md) for that bounded path
and the rank-three single-vector extension.

Triplet operands may be runtime expressions, including supported function calls
and array-element references. Either endpoint may be omitted, and stride defaults
to 1. An explicit stride must be nonzero. As with rank-one sections, both stride
signs default endpoints to the array's declared or dummy lower/upper bounds;
`a(::-1,:)` is usually empty, not a reversal. Use explicit descending endpoints.

Each nonempty triplet's first and last selected indices must be in bounds.
An unused endpoint need not be selected or in bounds: for an extent-four array,
`a(1:5:2,:)` fails because it selects 5, whereas `a(1:4:2,:)` selects 1 and 3.
An empty triplet does not check its endpoints against array bounds. Scalar
subscripts are always checked, including when another dimension is empty.
The runtime validates each dimension independently, including the selected
indices of a nonempty triplet when another dimension has extent zero. These
explicit safety checks are not claims about diagnostics required of compilers.

## Expressions, assignment and inquiries

```fortran
integer :: a(3,4), i, j
 do j=1,4
    do i=1,3
       a(i,j)=10*j+i
    end do
 end do
 a(:,2:4)=a(:,1:3)
 print *, a(3:1:-1,4:1:-1)
```

The assignment uses a complete snapshot of the old right-hand side. Overlapping
rows, columns and rectangular/strided regions are therefore safe. Before storing
anything, every target descriptor is frozen and every result is evaluated and
converted. Runtime errors do not partially commit an array assignment.

Sections work in supported arithmetic, comparisons, logical operations,
elemental intrinsics, scalar expansion and list-directed PRINT. The first
preserved dimension varies fastest. A scalar first subscript makes the second
source dimension the only result dimension. Conformance requires equal rank and
each dimension extent, even when the total element count is zero. Shape errors
involving sections are detected when executed, not by constant-folding triplets.
Scalar expansion evaluates the scalar once, including for an empty target.

SIZE, LBOUND and UBOUND accept these sections. Section lower bounds are always
1; upper bounds equal the dimension extents, including 0 for empty dimensions.
An extent-zero dimension does not erase other dimension extents. DIM ranges over
the result rank, so `size(a(i,:),2)` is an execution error. Inquiries resolve and
validate the subscripts without reading the selected data, so undefined array
elements do not prevent shape inquiries.

## Procedure association

A mixed scalar/triplet actual associates with a rank-one assumed-shape dummy;
a two-triplet actual associates with a rank-two assumed-shape dummy. IN dummies
may also receive section expressions, using temporary values. OUT and INOUT
actuals must remain direct writable designators. Types, REAL kinds and result
ranks must match exactly; dummy lower bounds are independent constants.

The caller freezes all selected addresses before executing the procedure.
Selected elements and definition flags follow column-major section order and
copy back only to their original addresses. This supports strided rows/columns,
reverse sections, empty sections, nested sections and mixed-rank forwarding.
OUT makes only the selected actual elements undefined; unselected elements retain
their previous values and flags. Partially initialized IN/INOUT direct actuals
can be passed if the callee never reads their undefined elements.

Alias checking uses selected addresses, not rectangular bounding boxes.
Intersecting writable actuals are rejected before the call body, while disjoint
and interleaved selections are accepted. Read-only aliases are allowed, empty
sections overlap nothing and expression temporaries are independent.
See [ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md) for the shared limits.

## Deliberate boundaries and verification

General vector subscripts, TRANSPOSE, pointers and assumed-size dummies were not
added by the 0.10 section feature. Later extensions cover
[numeric gathers](ROW-GATHER.md), [rank three](RANK-THREE.md),
[allocatables](ALLOCATABLES.md) and
[bounded explicit-shape dummies](EXPLICIT-DUMMY-BOUNDS.md). Later releases also support
rank-one constructors, [MATMUL/reductions](ARRAY-INTRINSICS.md), bounded
[automatic declarations](AUTOMATIC-ARRAYS.md), [PACK](PACK.md) and
[RESHAPE](RESHAPE.md). Numeric/logical array procedure results are described in
[ARRAY-RESULTS.md](ARRAY-RESULTS.md); function dummies remain IN-only.
Array sections cannot be used as declaration constant expressions. Existing resource and execution limits
still apply, with at most 1,000,000 materialized elements per frame/call.

The private IR records scalar/triplet classification and operand trees separately
for each source dimension. The FortFront adapter derives result rank/shape and
cross-checks every operand against the original AST. Runtime descriptors preserve
both source dimension counts and compressed result extents. Native mutation
tests and `tests/rank_two_sections` exercise independent GNU comparisons and
checked safety-policy failures. [VERIFICATION.md](VERIFICATION.md) records the
measured release results rather than implying support for all Fortran arrays.
