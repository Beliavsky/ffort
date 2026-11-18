# Bounded FINDLOC

FINDLOC accepts rank-one/rank-two INTEGER(4/8), REAL(4/8), default LOGICAL and
fixed-length/default CHARACTER arrays. VALUE must be scalar and have the same
intrinsic type as ARRAY. Numeric kinds may differ; mixed INTEGER/REAL types,
complex/unsigned values and higher-rank arrays remain outside this subset.
CHARACTER comparison uses Fortran blank padding, so differing lengths, trailing
blanks and zero-length strings compose with ordinary equality.

Without DIM, the result is a one-based coordinate vector with one component per
source dimension. With DIM it reduces rank by one. Returned positions refer to
the array expression's element order, independently of declaration lower bounds
and section strides. No match, an empty source, or a slice with no selected
matching value returns zero. BACK chooses the last match instead of the first.

MASK accepts scalar LOGICAL or a conforming LOGICAL array. KIND is a scalar
constant INTEGER expression equal to 4 or 8; default result kind is 4. Keyword
association is independently checked. Positional ARRAY,VALUE,DIM,MASK,KIND,BACK
is supported. Without DIM, the positional third argument may be LOGICAL MASK;
subsequent KIND/BACK arguments must be named. Direct OPTIONAL DIM/MASK/KIND/BACK
actuals retain the existing location-intrinsic restriction: use a PRESENT branch
and a nonoptional expression or local value. An optional VALUE is usable when
present, with checked failure if absent and evaluated.

## Evaluation and resource behavior

The implementation shares the checked location engine with MINLOC/MAXLOC.
ARRAY descriptors, options and mask conformance are checked before source data
scanning. Each selected ARRAY value and each array-mask value is evaluated once;
the engine scans every selected element even after finding an earlier match.
Unselected source values are not read. Scalar VALUE is evaluated exactly once,
including empty sources and all-false masks. This deterministic safety policy
can reject undefined VALUE data that another processor happens not to evaluate.

Only result coordinates are cached. FINDLOC does not keep copies of matching
CHARACTER values. Shapes, cache allocation, source element counts and scan work
use the configured 1,000,000-element and execution-budget bounds. Real values obey
the interpreter's existing finite-value policy. KIND(FINDLOC(...)) validates
metadata and constant result KIND without reading ARRAY, VALUE, DIM, MASK or
BACK data. Malformed public IR is checked separately from source acceptance.

The pinned frontend has an additional composition boundary: a scalar location
intrinsic supplied directly to an implicit-result user function can cause a
RESULT-name disagreement. The same case reproduces with MINLOC. An explicit
RESULT clause is verified to work. The negative fixture retains this rejection
rather than weakening the independent adapter.

## Original utility evidence

The source of record is `tests/utilities_slices/source/xutilities.f90`.
`tests/findloc/utility_compress_algorithm.f90` preserves the entire executable
algorithm from the original `compress`, including its exact FINDLOC statement:

```fortran
   imatch = findloc(values(:nfac),words(i),dim=1)
```

The fixture wraps that algorithm in new declarations. In particular, its
allocatable output dummy uses CHARACTER(*) instead of the original
CHARACTER(LEN=LEN(words)). The original specification-length allocatable dummy
is now supported. `utility_compress_declaration_blocked.f90` retains its historical
name and complete original procedure, and now passes checking and its empty main.
That fixture does not invoke the routine. The provenance checker verifies both
the executable block and complete original procedure against the source of record.
Separate exact-body execution appears in `tests/allocatable_character_lengths`;
see [the length-association contract](ALLOCATABLE-CHARACTER-LENGTHS.md). Full
utilities-program support is not claimed.

The differential driver exercises repeated words, order preservation,
reallocation and an empty input. Other fixtures cover type/kind/shape and
keyword combinations, masks, exact wide integers, blank padding, explicit
boundaries and undefined-data policies. A deterministic eight-matrix grid
checks 56 searched values, both DIM directions and first/last masked matches.
Native tests mutate the independent adapter and direct runtime metadata,
including skipped/unevaluated KIND operands.

Reference: [GNU Fortran FINDLOC](https://gcc.gnu.org/onlinedocs/gfortran/FINDLOC.html).
The supported implementation above is intentionally narrower than the full
Fortran intrinsic interface.
