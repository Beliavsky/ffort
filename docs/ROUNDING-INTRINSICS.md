# Integer rounding and base-ten logarithm

`NINT(A[,KIND])`, `FLOOR(A[,KIND])` and `CEILING(A[,KIND])` accept REAL(4/8)
scalars and rank-one/rank-two arrays. NINT rounds to the nearest integer, with
halfway values away from zero; FLOOR rounds toward negative infinity, and
CEILING toward positive infinity. The result has the shape of A, default INTEGER
kind 4, or INTEGER kind 4/8 selected by a scalar INTEGER constant expression.
Positional arguments and A=/KIND= keywords are supported, including reordered
keywords. Kind expressions may use parameters and supported constant inquiries.

`LOG10(X)` accepts the same REAL inputs, preserves their REAL kind and shape,
and supports X=. Values actually evaluated must be positive and finite.

These pure elemental calls compose with constant expressions, PARAMETERs,
array results, ordinary strict procedure actuals, sections, nested arithmetic
and empty arrays. KIND inquiries derive the result kind without reading A/X.
Malformed metadata is still checked when no element is evaluated.

Rounding happens in the interpreter's REAL(8) value representation before any
integer conversion. Conversion checks the rounded result against the selected
INTEGER range; it does not invoke an overflowing host FLOOR/CEILING/NINT integer
conversion. REAL(4) inputs have already been rounded to their declared precision.
Non-finite arguments and out-of-range results produce checked execution errors.
Constant-evaluation errors reject the source. Failed PRINT expression evaluation
produces no partial record. Check mode validates source and metadata, not runtime
values or definedness.

Excluded: complex or wider REAL inputs, INTEGER kinds other than 4/8, variable
KIND arguments, rank three and above, legacy specific names such as IDNINT/DLOG10,
and other unlisted intrinsics. Supporting these four intrinsics does not imply
full utility-file support.

## Verification and source provenance

`test/test_rounding_intrinsics.f90` exercises the independent adapter and direct
runtime IR, including result/input type and kind, missing/extra/invalid arguments,
self-cycles, shape mismatches, KIND inquiries and nested empty expressions.
`tests/rounding_intrinsics/run_tests.py` performs GNU Fortran comparisons and
fail-closed invalid/unsupported/runtime checks, including signed ties, exact
INTEGER(8) results, 32/64-bit boundaries and a source-hashed original-body fixture.
The original floor_10 and ceiling_10 routines are retained unchanged except CRLF
normalization. Their reduced module and driver are new harness code.

GNU intrinsic references:
- https://gcc.gnu.org/onlinedocs/gfortran/NINT.html
- https://gcc.gnu.org/onlinedocs/gfortran/FLOOR.html
- https://gcc.gnu.org/onlinedocs/gfortran/CEILING.html
- https://gcc.gnu.org/onlinedocs/gfortran/LOG10.html
