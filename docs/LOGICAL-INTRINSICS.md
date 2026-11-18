# Logical reductions, selection and double-precision conversion

The interpreter supports `ALL(MASK [, DIM])`, `ANY(MASK [, DIM])`,
`COUNT(MASK [, DIM] [, KIND])`, `MERGE(TSOURCE, FSOURCE, MASK)` and `DBLE(A)`.
Names may be shadowed by an explicit user procedure or array declaration.
Arguments support standard case-insensitive keywords, positional arguments
before keywords, and independent source/AST association checks.

## ALL, ANY and COUNT

MASK is a rank-one or rank-two LOGICAL expression, including a section, comparison,
constructor or assumed-shape dummy. Without DIM the result is scalar. DIM is a
scalar INTEGER expression checked against the actual rank at execution time.
Rank-one DIM reductions return scalars; rank-two DIM reductions return vectors.
`DIM=1` reduces each column and `DIM=2` reduces each row, including reversed or
strided sections. Result shape is derived at runtime before any result is emitted.

COUNT returns default INTEGER(4), or INTEGER(4/8) selected by a scalar INTEGER
constant KIND. `count(mask,kind=8)` does not supply DIM. Nondefault LOGICAL kinds
remain outside the supported subset.

For an empty reduction, ALL returns true, ANY returns false and COUNT returns
zero. A rank-two reduction over a zero extent returns a vector of these identities;
a zero extent in the retained dimension returns an empty vector. Every visited
MASK element is checked for definition and charged to the shared execution budget.
There is no short-circuit promise: a later undefined element still diagnoses an
error after ALL/ANY already has a mathematically decisive value.

## MERGE and DBLE

MERGE selects TSOURCE where MASK is true, and FSOURCE elsewhere. Sources must have
the same supported intrinsic type and kind; CHARACTER sources must also have the
same length. MASK is LOGICAL. Numeric, LOGICAL and CHARACTER sources support scalar
expansion and conformable rank-one/rank-two arrays. Equal element count alone does
not make differently shaped matrices conformable. Derived-type sources remain
unsupported. Runtime CHARACTER lengths and dynamic section shapes are checked.

MERGE is elemental selection, not conditional execution. Both source arguments
are evaluated for each output element. An undefined or erroneous unselected source
therefore fails under the interpreter's deterministic evaluation policy. An empty
result has no values to evaluate, but its structural type/shape checks still run.

DBLE converts supported INTEGER(4/8) or REAL(4/8) expressions to REAL(8), preserving
array rank and shape. Integer values above the exact binary64 integer range round
normally, as they do in GNU Fortran. Complex values remain unsupported.

These intrinsics can be used in PARAMETER initialization and constant bounds.
Existing restrictions on frontend-resolved declaration kind selectors remain:
for example a named REAL kind parameter initialized through MERGE is rejected
rather than approximated. `KIND` inquiries inspect supported result metadata without
evaluating otherwise undefined argument values.

## Verification

`tests/logical_intrinsics/run_tests.py` checks independently specified results,
GNU Fortran differential behavior and rejection/runtime-policy cases. It covers
both DIM directions, zero extents, reversed sections, keyword permutations, kind
preservation, large integers, scalar expansion, CHARACTER values, nested reductions,
constant initialization, shadowing and unevaluated inquiries. Invalid types, kinds,
lengths, shapes, argument lists, runtime DIM and execution limits are checked.
`test/test_logical_intrinsics.f90` independently mutates adapter and direct-runtime
IR metadata (185 assertions). The existing exact `frac_true` utility extract and
MERGE probe now pass; historical fixture filenames are retained.

The focused FortFront registration and resolved-metadata changes are recorded in
`vendor/patches/0029-logical-selection-conversion-intrinsics.patch`.
