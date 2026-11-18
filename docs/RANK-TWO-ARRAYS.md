# Rank-two arrays (updated for 0.10.0)

Later releases add [bounded explicit-shape dummies](EXPLICIT-DUMMY-BOUNDS.md);
the historical boundary section below describes the 0.10 feature. Current
[rank-three arrays](RANK-THREE.md) and [numeric vector gathers](ROW-GATHER.md)
are separate extensions; rank-two gathering is still row-only.

Array reductions and vector/matrix products added in 0.11.0 are documented in [ARRAY-INTRINSICS.md](ARRAY-INTRINSICS.md).
## Shape, element order and expressions

```fortran
integer :: a(-1:0,3:5), b(2,3), i, j
 do j=3,5
    do i=-1,0
       a(i,j)=10*j+i
    end do
 end do
 b = a + a(-1,3)
 print *, b
```

This prints values `58 59 68 69 78 79`. The first subscript varies fastest,
so `a(-1,3)`, `a(0,3)`, `a(-1,4)` are consecutive elements. Each dimension
uses a constant INTEGER upper bound or lower:upper pair. Nonunit and negative
lower bounds are supported independently. A zero extent in either dimension
makes total storage empty, without losing the other dimension's extent.
Each dimension extent must fit signed 32-bit INTEGER; total declared elements,
elements per runtime frame, and array elements materialized for one call each
remain bounded by 1,000,000. Extents and their product are checked using int64.

Element references use exactly two scalar INTEGER subscripts. Triplet sections
and mixed scalar/triplet references are described in [RANK-TWO-SECTIONS.md](RANK-TWO-SECTIONS.md). The runtime checks both independently;
an out-of-range first index cannot spill into the next column. Elements have
independent definition flags. A well-typed invalid index is accepted by --check
and fails during execution if reached, just as with rank-one arrays.

Whole-array assignment, arithmetic, comparisons, logical operations, supported
elemental intrinsics, scalar expansion and list-directed PRINT work for rank two.
Both rank and every dimension extent must conform. Arrays of shape `(2,3)` and
`(3,2)` are not conformable, even though they have the same element count. Lower
bounds do not affect conformance. Empty shapes still require per-dimension
conformance. Constant shape conflicts are rejected before execution; conflicts
involving assumed-shape arguments are checked at runtime.

Assignments compute and convert all results before committing. For example,
`a = a + a(-1,3)` uses the old element throughout. Scalar expansion evaluates
its scalar once, even into an empty array; empty array-valued expressions do not
read their data elements. These are the prototype's deterministic safety rules,
not a claim about every compiler's optional expression evaluation choices.

## Inquiries

- `size(a)` gives total element count.
- `size(a,1)` and `size(a,2)` give the corresponding dimension extent.
- `lbound(a,dim)` and `ubound(a,dim)` give scalar bounds for that dimension.
- DIM may be a scalar INTEGER runtime expression and must be 1 or 2 for rank two.
- For a whole variable, a nonempty dimension exposes its declared or dummy bounds.
  An empty dimension exposes 1:0; another nonempty dimension retains its bounds,
  even if total storage is empty.
- Array expressions and parenthesized arrays have lower bounds 1. Inquiries do
  not read element values, so they are valid on undefined array data.

KIND and keyword arguments, LBOUND/UBOUND without DIM, and inquiry expressions
in declaration bounds remain unsupported.

## Procedure association and local storage

```fortran
subroutine shift(values)
    real(kind=8), intent(inout) :: values(-1:,3:)
    values = values + 1.0d0
end subroutine shift
```

Rank-two assumed-shape dummies accept whole rank-two actuals and two-triplet sections. IN may also accept
shape-conforming array expressions, which use temporaries. Dummy lower bounds
are independent constants (default 1); each upper bound follows from its actual
extent. A direct binding carries per-element definition flags without eagerly
reading the data. OUT invalidates every associated element, including unwritten
ones; INOUT preserves incoming flags. Nested forwarding preserves column-major
order, shape and definition state. Scalar array-element actuals may address a
rank-two element. Their two indices are frozen before the callee executes.

Exact types, REAL kinds and ranks are required. Overlapping direct actuals are
rejected if either corresponding dummy is writable; read-only aliases and
nonoverlapping element actuals are allowed. Empty bindings overlap nothing.

Procedure locals may be explicit-shape rank one or two, with constant or
[bounded automatic bounds](AUTOMATIC-ARRAYS.md) and fresh undefined storage on
every invocation. Array declaration initializers and mutable initialized locals
remain unsupported. [Numeric/logical array results](ARRAY-RESULTS.md) are supported;
function dummy arguments remain IN-only. Shared execution and frame
limits still apply.

`examples/matrix_multiply.f90` computes a matrix product through rank-two IN and
OUT dummies using explicit loops. Its column-major result is `76 100 103 136`,
followed by total/row/column counts `4 2 2`. It does not use a hidden compiler
backend or MATMUL. The intrinsic itself is supported by later releases.

## Deliberate boundary

Rank-two sections, including `a(:,j)`, `a(i,:)`, `a(:,:)` and strided/mixed
triplets, are supported in 0.10.0. Rank-one sections retain all previous behavior.
Rank three or higher, vector subscripts, TRANSPOSE, dynamic or
explicit-shape dummy bounds, assumed-size/deferred-shape arrays, allocation,
CHARACTER/derived array results and unlisted array features are rejected
explicitly. Rank-one constructors and [MATMUL/reductions](ARRAY-INTRINSICS.md)
are supported by later releases. Bounded [PACK](PACK.md) and [RESHAPE](RESHAPE.md)
are supported in 0.22.0.

The private IR retains dimension extents separately from total storage size.
The frontend adapter independently derives and cross-checks both dimensions,
bounds, expression shapes and element references against the FortFront AST.
Native mutation tests exercise false caches/bindings; `tests/rank_two` supplies
independent expectations and GNU Fortran checks. See VERIFICATION.md for the
measured release results and limitations.
