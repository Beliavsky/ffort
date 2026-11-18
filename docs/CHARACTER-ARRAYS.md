# CHARACTER arrays and expressions

Fixed-length default CHARACTER now supports explicit-shape rank-one and rank-two
arrays, elements, sections, whole-array assignment, scalar expansion and PARAMETER
arrays. Declared lengths are nonnegative integer literals or previously defined
scalar INTEGER PARAMETER names, optionally introduced with `LEN=`. PARAMETER
entities also support inferred `LEN=*`; see [CHARACTER-PARAMETERS.md](CHARACTER-PARAMETERS.md). The existing
per-value maximum is 65,536 characters.

The requested example is `examples/character_arrays.f90`. It prints three padded
values, three values prefixed with a blank, and the comparisons `T F T`.

## Constructors and concatenation

- Untyped `[items]` and `(/items/)` CHARACTER constructors require matching, fixed or supported descriptor-known runtime
  item lengths, including folded constant TRIM lengths. Their scalar and rank-one
  items concatenate in element order.
- `[character(len=n) :: items]` and `(/character(n) :: items/)` specify the element
  length explicitly and pad or truncate every item. `character ::` means length
  one. Typed empty CHARACTER constructors are supported in both spellings.
- `//` concatenates CHARACTER expressions, with scalar expansion for array operands
  and rank/extent conformance checks for two array operands. It binds less tightly
  than arithmetic and more tightly than comparisons, following Fortran precedence.
- Comparisons retain Fortran blank-padding semantics and produce LOGICAL arrays.
- Assignment pads or truncates to the destination element length. Whole-array and
  section assignments retain the existing temporary-before-commit overlap policy.
- SIZE, LBOUND, UBOUND and KIND inquiries work with the supported CHARACTER arrays.
  Zero-sized arrays preserve type/length and need no data-element evaluation.

CHARACTER array dummies, array function results and bounded procedure-local
runtime lengths are described in [CHARACTER-PROCEDURES.md](CHARACTER-PROCEDURES.md).
Substrings of array sections, nondefault CHARACTER kinds, scalar deferred-length/allocatable CHARACTER,
nonempty numeric typed constructors and untyped constructors
with value-dependent item lengths remain outside this subset. Descriptor-known
runtime constructor lengths are covered in [DYNAMIC-CHARACTER-CONSTRUCTORS.md](DYNAMIC-CHARACTER-CONSTRUCTORS.md). Scalar-base
substrings are covered in [CHARACTER-SUBSTRINGS.md](CHARACTER-SUBSTRINGS.md). Scalar
array-element substrings use [ARRAY-ELEMENT-SUBSTRINGS.md](ARRAY-ELEMENT-SUBSTRINGS.md).

## Verification

`tests/character_arrays` contains 49 differential and boundary cases. GNU Fortran
is used directly for 48 cases: 33 executions, six compile-only cases, and nine
required rejections. One interpreter resource-limit case skips GNU.
The native tests separately cover 17 adapter metadata mutations, 10 direct-runtime
corruptions, padding and overlap, constant constructor values, and four empty
constructor producer shapes/type specifications. Vendor patch 0021 retains the
empty legacy typed-constructor parser fix.

Bounded allocatable CHARACTER arrays are covered in [ALLOCATABLE-CHARACTER.md](ALLOCATABLE-CHARACTER.md).
