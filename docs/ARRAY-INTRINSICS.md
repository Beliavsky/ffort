# Array reductions and products (0.11.0)

The interpreter now executes `SUM`, `PRODUCT`, `MINVAL`, `MAXVAL`,
`DOT_PRODUCT` and `MATMUL` directly. These are interpreted operations, not calls
to GNU Fortran, BLAS, a compiler backend or generated native code.

## Reductions

All four reductions accept INTEGER, REAL(4) and REAL(8) arrays of rank one or
two. The result preserves the input element type and kind. Supported positional
forms are:

```fortran
sum(array)
sum(array, dim)
sum(array, mask)
sum(array, dim, mask)
```

The same forms apply to PRODUCT, MINVAL and MAXVAL. DIM is a scalar INTEGER
expression. MASK is either a scalar LOGICAL expression or a LOGICAL array with
exactly the same rank and dimension extents as ARRAY. Bounds need not match.
The second-argument LOGICAL overload means MASK without DIM, not conversion of
LOGICAL to INTEGER. ARRAY, DIM and MASK keyword arguments are supported; see [KEYWORD-ARGUMENTS.md](KEYWORD-ARGUMENTS.md).

Without DIM the result is scalar. With DIM it has rank `rank(array)-1`, with
the selected dimension removed. A rank-two reduction therefore returns a
rank-one array; a rank-one reduction returns a scalar. Runtime DIM values are
supported, so extents are resolved at execution. DIM outside 1..rank(ARRAY) is
an execution error, even when supplied as a literal. This matches the existing
inquiry policy: `--check` checks syntax/types without evaluating DIM values.

Examples for a 2-by-3 matrix:

```fortran
print *, sum(a)          ! One total.
print *, sum(a,1)        ! Three column totals.
print *, sum(a,2)        ! Two row totals.
print *, maxval(a,a>0)   ! Maximum selected positive value.
print *, product(a,1,a/=0)
```

Reduction values use Fortran array element order, with the first dimension
varying fastest. DIM reductions use that dimension's element order. Real
operations round in the result kind after each product or addition. Fortran
permits different reduction evaluation orders, so cancellation-sensitive
floating results need not be bit-identical to every compiler or optimization
level. Tests use independent mathematical expectations and GNU Fortran where
applicable, with explicit tolerances or exactly representable examples.

### Empty or fully masked reductions

Each empty selected set, including an individual DIM slice, has these results:

- SUM: zero of the input type/kind.
- PRODUCT: one of the input type/kind.
- MINVAL: the largest supported value of the input type/kind.
- MAXVAL: the negative value of largest supported magnitude. For this signed
  32-bit INTEGER model that is -2147483648, not -2147483647. For REAL it is
  the negative largest finite value of that kind.

Empty input and an empty result are different. For example, reducing a
`(0,3)` array along dimension 1 returns three identities, while reducing it
along dimension 2 returns a zero-length vector.

## Vector and matrix products

DOT_PRODUCT takes two rank-one arrays of equal size and returns a scalar.
MATMUL accepts exactly these pairs:

| Left | Right | Result | Conformance |
| --- | --- | --- | --- |
| rank 2 `(m,k)` | rank 2 `(k,n)` | rank 2 `(m,n)` | Inner extents equal |
| rank 2 `(m,k)` | rank 1 `(k)` | rank 1 `(m)` | Inner extents equal |
| rank 1 `(k)` | rank 2 `(k,n)` | rank 1 `(n)` | Inner extents equal |

Two vectors are invalid for MATMUL; use DOT_PRODUCT instead. Different lower
bounds do not affect pairing. Section order is honored, including reversal,
nonunit strides and rank-reducing matrix slices.

Numeric operands may mix INTEGER, REAL(4) and REAL(8). Result type and kind
follow ordinary multiplication: two INTEGER arrays produce INTEGER; otherwise
REAL, using the larger participating REAL kind. Integer values are converted
when a REAL operation is needed. Two LOGICAL arrays are also supported: each
output is the OR of pairwise AND values. Mixing LOGICAL and numeric operands is
rejected. Complex arithmetic is not supported.

An empty inner dimension produces numeric zeros or LOGICAL false values. A
zero outer dimension produces an empty result with its other extent retained.
All array-valued results have expression lower bounds of one, including when
used in SIZE/LBOUND/UBOUND inquiries.

## Composition and safety

Operands can be whole arrays, sections, conforming elemental expressions or
other supported array-intrinsic results. Results work in assignment, PRINT,
inquiries, nested reductions and assumed-shape IN arguments. Scalar intrinsic
results can be used wherever an ordinary scalar expression is allowed. Array
procedure results and array constants remain outside the subset.

The runtime resolves sections, DIM and all required shape relations before
reading intrinsic data. Shape inquiries on intrinsic results do not read ARRAY
or MASK element values. Section bounds and scalar DIM expressions are still
evaluated, and can fail. The descriptor and DIM are frozen per expression
occurrence for the current statement and refreshed on the next statement or
loop iteration.

A false MASK skips the corresponding ARRAY data expression, so unselected
uninitialized data and arithmetic are not read. MASK array values that are
needed are checked like other data. Scalar MASK is evaluated when computing a
reduction value, including an identity for an empty input; an empty output
vector evaluates no scalar MASK/data values. This is the prototype's explicit
safety/evaluation policy, not a promise about optional expression evaluation by
every Fortran compiler. LOGICAL products evaluate both input values and check
initialization even after their accumulator has become true.

Assignment remains overlap-safe: every RHS result and conversion is computed
before any target element changes. A failed PRINT emits none of that record.
Each selected product/addition checks signed 32-bit integer overflow and
non-finite REAL results immediately, including intermediate values. All shape
work and reduction/product iterations consume the existing shared execution
budget. The implementation computes one result element at a time and does not
allocate unbounded matrix temporaries. A single array result is limited to
1,000,000 elements before traversal, including a large result inferred from two
zero-element operands. Declaration/frame/argument limits remain in force.

The syntax recognizer and FortFront adapter independently derive intrinsic
result rank/type/kind and validate argument structure. Runtime descriptor
checks also defend direct IR callers. The new intrinsic names remain usable as
explicitly declared variables or procedures; those declarations take priority,
preserving the existing module function named SUM regression.

See `examples/array_intrinsics.f90`,
`test/test_array_intrinsics_frontend.f90`,
`test/test_array_intrinsics_runtime.f90` and
`tests/array_intrinsics_independent/README.md`.
