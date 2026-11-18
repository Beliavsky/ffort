# Explicit typed empty intrinsic constructors

The bounded 0.41 extension accepts `[integer::]`, `[real::]`, `[logical::]`,
INTEGER/REAL kind 4 or 8 selectors, and their `(/ type-spec :: /)` counterparts.
Numeric KIND selectors are an unsuffixed literal 4/8 or a named scalar INTEGER
PARAMETER. Named parameters may themselves be defined using supported KIND or
SELECTED_* inquiries, or imported through ISO_FORTRAN_ENV aliases. Default LOGICAL
uses kind 4. Existing typed CHARACTER behavior is unchanged.

Every new expression is intrinsically rank one with extent zero and an allocated
zero-length argument list. Numeric type markers and a distinct selector reference
keep these expressions separate from malformed untyped-empty IR. The source guard,
FortFront adapter, and direct runtime independently validate the marker, type, kind,
selector, extent, rank and unused metadata. The adapter binds the exact selector
text and lexical symbol, checks its scope, and requires independent producer
rank/type/kind. Runtime validation also runs under KIND, inquiries, and zero-sized
scalar-expansion expressions, without evaluating data items.

Empty constructors work as constant arrays, nested untyped-constructor items,
INTENT(IN) assumed-shape actuals, inquiry/reduction inputs, and assignment or
allocatable reallocation expressions. Typed empty constructors do not change
resource policy. The later capacity extension sets the default aggregate element
cap to 1,000,000; see `docs/ARRAY-LIMITS.md` for the shared setting. Independent
execution/source/token caps remain unchanged.

Deliberate boundaries: untyped `[]` and `(//)`; nonempty explicitly typed numeric
or logical constructors (including implicit conversion); arbitrary implied-DO;
direct inquiry calls or arithmetic inside constructor KIND selectors; kind values
other than 4/8; explicit LOGICAL kind selectors; DOUBLE PRECISION type spelling;
derived and complex type specs; and writable constructor actuals. A declaration
of a named parameter is the supported way to reuse a computed kind. This work
does not broaden the prototype's reserved-keyword policy.

## Evidence and preserved history

`run_tests.py` uses exact Decimal values, preserves signed zero, rejects nonfinite
numeric tokens, and compares text tokens exactly. Formatted historical output is
byte-exact. No float tolerance is used. `test_runner.py` tests the comparator.
`test/test_typed_empty_arrays.f90` independently mutates IR at adapter and runtime
boundaries and checks producer metadata.

The strict suite executes the complete, byte-preserved historical drivers:
- `allocatable_spec_inquiries/original_filter_matrix_rows_gnu`: exact original
  filter body with unchanged synthetic helper implementations, result `1`.
- `release034_integration/original_filter_dependency_boundary`: unchanged driver
  plus all three exact original routine bodies, exact formatted matrix and shape.
- `mean_programs_independent/constructor_unsupported_typed_empty`: historical name
  retained, complete source now prints `0`; its shipped generator is promoted too.

The nine `row_gather` full original closures remain separate evidence and are not
substitutes for these older drivers. The complete xutilities attachment is still
unsupported at line 9329, column 55: its 100-million-element declaration exceeds
the configured array cap, including the measured 10-million-element option.
All existing Fortran source fixtures and original source bytes are unchanged.

A preliminary GNU 14 test passing an empty fixed-length CHARACTER constructor
straight to a fixed-length dummy encountered a GNU runtime descriptor error.
That proposed new case was not retained as GNU success evidence; no existing
CHARACTER source or expected result was changed, and the complete existing
CHARACTER array suite is rerun.

Run after building:

```
python3 tests/typed_empty_arrays/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran gfortran
python3 tests/typed_empty_arrays/test_runner.py
fpm test --target test_typed_empty_arrays
```
