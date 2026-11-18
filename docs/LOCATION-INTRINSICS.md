# Bounded MINLOC/MAXLOC

MINLOC and MAXLOC accept rank-one and rank-two INTEGER or REAL arrays of kind 4
or 8. The result is default INTEGER unless a constant KIND=4 or KIND=8 is supplied.
An absent DIM produces a vector containing one coordinate per source dimension.
DIM reduces rank by one, so a vector with DIM produces a scalar. Runtime DIM
values are checked before values are consumed, including empty results.

Optional MASK is scalar LOGICAL or a conformable rank-one/two LOGICAL array.
BACK selects the last tied extremum instead of the first. Locations are one-based
positions in array element order, not source declaration bounds. Empty arrays and
slices with no selected elements produce zeros. Rank-two traversal follows
Fortran column-major order. Each selected source value and each array MASK value
is evaluated once per intrinsic execution; results are cached before assignment.
INTEGER(8) comparisons remain integer comparisons, avoiding conversion through
REAL and loss of precision above 2**53.

Positional ARRAY,DIM,MASK,KIND,BACK and keywords are supported. With DIM omitted,
ARRAY,MASK may be positional; KIND and BACK must be named. Unknown, duplicate,
missing and misplaced arguments are rejected. Direct OPTIONAL dummies passed as
DIM, MASK, KIND or BACK are deliberately rejected; use an explicit PRESENT branch
and an ordinary actual value. CHARACTER/UNSIGNED sources, higher ranks and wider
result kinds remain unsupported. Non-finite values follow the interpreter's
existing real-value safety policy, rather than defining NaN ordering.

Scalar KIND inquiries validate the intrinsic metadata and the constant result
KIND but do not evaluate ARRAY, DIM, MASK or BACK. The independent source adapter
checks slots, rank, type, kind and shape. The runtime separately checks descriptors,
indices, option types, kinds, conformance, array/cache capacities and execution
budget, including malformed IR and zero-size results.

## DIMENSION attribute

The original DIMENSION milestone below predates
[bounded explicit-shape dummies](EXPLICIT-DUMMY-BOUNDS.md), which also support
the DIMENSION attribute for their documented rank-one/two/three shapes.

The declaration recognizer accepts DIMENSION(...) as an alternative spelling of
the existing declarator shape syntax for supported rank-one/two arrays. Bounds
follow the same constant/automatic restrictions; procedure dummies remain
assumed-shape with explicit INTENT. Multiple names share the attribute. An entity
shape combined with a DIMENSION attribute, repeated DIMENSION attributes,
standalone DIMENSION statements, allocatables, explicit-shape dummies and rank
three remain unsupported. Combined attribute/entity shapes are explicitly
rejected because the pinned frontend does not preserve that override reliably.

This additional declaration syntax is required by the unchanged original
`iminloc` body, which declares both its assumed-shape input and one-element work
array with DIMENSION attributes. Supporting it does not enable the full utilities
module. See `tests/location_intrinsics/README.md` for exact-source provenance and
GNU comparisons.

Reference semantics:
- https://gcc.gnu.org/onlinedocs/gfortran/MINLOC.html
- https://gcc.gnu.org/onlinedocs/gfortran/MAXLOC.html
