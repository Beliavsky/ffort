# Scalar and vector array-bound inquiries

`LBOUND(ARRAY [, DIM, KIND])` and `UBOUND(ARRAY [, DIM, KIND])` accept
supported INTEGER(4/8), REAL(4/8), default LOGICAL and default CHARACTER arrays
of rank one, two or three. Positional arguments and the standard ARRAY, DIM,
KIND keywords are associated independently by the guard and producer adapter.

Without DIM, the result is a rank-one INTEGER vector with ARRAY-rank elements.
With scalar INTEGER(4/8) DIM, the result is scalar and DIM must select an axis.
KIND is a scalar constant INTEGER expression selecting 4 or 8; the default is 4.
Scalar bound results expand in surrounding array expressions. SIZE is unchanged.
No assumed-rank, assumed-size or rank-four support is added.

## Bounds and value evaluation

For a whole object, each nonempty axis preserves its actual lower/upper bound.
For a zero-extent axis LBOUND is 1 and UBOUND is 0, independently of other axes.
This includes an empty assumed-shape dummy with minimum default-INTEGER lower
bound: only its zero-extent descriptor may carry upper = lower - 1 below that
range. That sentinel is never returned, and nonempty/default-integer range
guards remain in force.
Parenthesized arrays, array expressions, sections, reversed sections and array
function results use normalized lower bound 1 and upper bound equal to extent.
Assumed-shape dummies use their own associated descriptor, including explicit
lower bounds on the dummy declaration, rather than the caller's bounds.

Whole explicit-shape, allocated allocatable and associated pointer inquiries
read descriptors rather than element values. Undefined array elements are
therefore allowed. Explicit declared bounds can contribute constant expressions,
including PARAMETER vector initializers. Existing bounded specification-expression
rules continue to govern automatic objects and explicit-shape dummies.
Supported simple sections and static arithmetic shapes also do not read elements.
General value-producing array expressions retain their existing shape-preparation
rules; this feature does not promise to avoid all evaluation of arbitrary calls,
gathers, PACK or other transformations.

An evaluated whole allocatable ARRAY must be allocated; an evaluated pointer
ARRAY must have valid, associated status. KIND of the inquiry is metadata-only:
it does not inspect allocation, data values, absent OPTIONAL ARRAY state, or
execute a DIM function body. Constant-invalid DIM, invalid metadata, cyclic
expression graphs, unsupported kinds and malformed symbol/shape bindings still
reject, including through KIND and empty surrounding arrays. A direct OPTIONAL
DIM dummy is rejected as required by the intrinsic's argument restrictions.
The existing one-dimensional numeric pointer subset is not expanded.

## Validation and source preservation

The source suite has 149 exact cases: 113 candidate/GNU execution agreements,
4 explicit pre-existing reserved-name boundaries (GNU-only execution), 12 safe
runtime-policy cases checked against GNU compilation only, and 20 invalid cases
rejected by both compilers. The unchanged M_intrinsics `demo_shape.f90` is one
of the execution agreements; provenance and license hashes are in the suite.
The independent native test has 8,548 assertions covering result/operand descriptors, symbol bindings,
formal masks, KIND, graph cycles, empty surrounding arrays and public constant
inquiry evaluation. A separate producer test has 28 metadata/binding cases.
The strict runner has 28 adversarial self-tests and requires empty successful
stderr/check stdout, plus truly empty run stdout when no output is expected.

The historical rank-two `matrix_bound_vector_result` fixture is promoted only
through its manifest and generator expectations, from unsupported to output
`111 1 1`. Four historical keyword probes, `unsupported_390` through
`unsupported_393`, are likewise promoted to exact GNU execution for scalar KIND
and vector forms. Every historical Fortran source remains unchanged.
One historical native test's legal
alternate SIZE-to-LBOUND IR setup now adds `intrinsic_mask=3` for ARRAY+DIM;
all of its embedded source and rejection assertions remain unchanged.
The separate NORM2 scalar-expansion correction is not part of this feature delta.

## References

- [Fortran 2023 draft 23-007r1](https://j3-fortran.org/doc/year/23/23-007r1.pdf),
  16.9.119 LBOUND and 16.9.215 UBOUND.
- [GNU LBOUND documentation](https://gcc.gnu.org/onlinedocs/gfortran/LBOUND.html)
- [GNU UBOUND documentation](https://gcc.gnu.org/onlinedocs/gfortran/UBOUND.html)

Run `python3 tests/array_bounds_inquiry/test_runner.py`, then
`python3 tests/array_bounds_inquiry/run_tests.py --candidate /path/to/cli --gfortran /path/to/gfortran`.
GNU is an independent oracle, never an interpreter execution backend.
