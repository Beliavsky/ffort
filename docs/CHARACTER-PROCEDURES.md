# Bounded CHARACTER procedure storage

Default CHARACTER now supports rank-one/rank-two assumed-shape dummy arrays and
explicit-shape array function results. This includes the unchanged
`concat_char_vec` routine extracted from the supplied utilities source.

## Supported declarations

- Scalar and array `CHARACTER(*)` dummies with explicit INTENT(IN), INTENT(OUT),
  or INTENT(INOUT), subject to the existing function/purity restrictions.
- Fixed-length assumed-shape arrays. Their actual element length must match
  exactly, including zero-sized arrays. The existing scalar input-dummy rule
  still permits a longer actual and truncates the dummy's view.
- Procedure-local scalars and explicit-shape rank-one/rank-two arrays whose
  length is an integer specification expression. Function results use the same
  local storage rules. Declare such results in the procedure body.
- Length expressions use the existing bounded automatic-array integer grammar:
  input/inout INTEGER dummy values, parameters, integer arithmetic, ABS, MIN,
  MAX, MOD/MODULO and supported array inquiries/COUNT masks. LEN of a previously
  declared CHARACTER dummy is also allowed, either whole or a scalar array
  element through rank three, such as `LEN(x(1))` or `LEN(x(i,1,1))`. Subscripts
  use the same bounded integer specification-expression grammar. The length
  inquiry reads the descriptor without evaluating subscripts or array data, so
  its value is independent of the dummy's initialization state or extent.
- Lengths and bounds are evaluated once after argument association, before
  procedure-body execution. Later dummy changes do not resize local storage.
  Negative calculated lengths become zero; the per-value maximum remains 65,536.

The result owns its storage. Assignment pads/truncates to the destination's
length, and empty results keep their element length without sampling an element.
IN/OUT/INOUT association, sections, expression actuals and nested forwarding use
existing checked shape/copy/alias rules. Array argument and result storage remains
charged to the configured 1,000,000-element frame/temporary limits.

Bounded explicit-shape dummies of ranks one through three are covered in
[EXPLICIT-DUMMY-BOUNDS.md](EXPLICIT-DUMMY-BOUNDS.md).

## LEN

`LEN(string)` and `LEN(string=...)` return default INTEGER for scalar or array
CHARACTER arguments. For declared variables, elements and sections, LEN reads the
length descriptor without reading data or evaluating subscripts. Fixed-length
expressions likewise need no value evaluation. Dynamic array function results
use the cached invocation descriptor. A value-dependent scalar expression, such
as TRIM or a runtime-length scalar function result, is evaluated to obtain its
length. KIND= on LEN is not included.

The independent adapter compares FortFront's retained length-expression text
against the guarded expression tree, including operator precedence and scoped
symbol bindings. Runtime checks validate supported expression structure, length
ranges and actual/result descriptors; an empty array does not bypass validation.

## Boundaries

Scalar deferred-length/allocatable CHARACTER, dynamic explicit-length dummies,
substrings of array sections/function results, writable substring actuals,
nondefault kinds, initialized runtime-length saved CHARACTER and assumed-length results remain
unsupported. Direct bounded PURE module specification functions are described in
[SPECIFICATION-FUNCTIONS.md](SPECIFICATION-FUNCTIONS.md). Other general
specification functions and runtime lengths in typed
constructors are not added. PACK and RESHAPE retain their fixed-length CHARACTER
restrictions. The full utilities source still requires additional features.

Scalar array-element substring reads, assignments and bounded input actuals
are described separately in [ARRAY-ELEMENT-SUBSTRINGS.md](ARRAY-ELEMENT-SUBSTRINGS.md).
Writable substring actuals remain excluded.

## Verification

`tests/character_procedures/run_tests.py` runs source checks, execution and strict
GNU Fortran oracle stages using `-std=f2018 -pedantic-errors -fcheck=all -O0`.
The corpus includes exact original routine bytes, padding, rank-two arrays,
empty/undefined values, expression actuals, nested results, entry-time freezing,
negative lengths, resource errors and unsupported declarations. Its manifest
separates GNU executions, compile-only safety cases and required rejections.

`test/test_character_procedures.f90` adds 15 independent adapter mutations and
nine direct-runtime corruption checks. `test/test_character_producer.f90` covers
the corresponding canonical producer types and length-token preservation.
Vendor patch 0039 records the producer corrections. No compiler is used by the
interpreter to execute submitted Fortran.

For bounded allocatable CHARACTER arrays and dummies, see [ALLOCATABLE-CHARACTER.md](ALLOCATABLE-CHARACTER.md).

OPTIONAL CHARACTER dummies follow [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).

Scalar-base substring reads/writes are covered in [CHARACTER-SUBSTRINGS.md](CHARACTER-SUBSTRINGS.md).

The old `optional_character_reject.f90` fixture remains byte-for-byte as source
provenance; the manifest uses its identical `optional_character_supported.f90`
copy with the newly supported expectation.

## Element inquiries in specification expressions

`tests/character_len_elements` verifies LEN of array elements in procedure-local
lengths and function result lengths, including empty arrays, zero-length values,
INTENT(OUT) data, fixed/deferred allocatable descriptors, integer dummy subscripts,
and the byte-exact original `prepend_char` utility routine. Its 19 cases compare
14 safe executions with GNU Fortran and separately check four compile-only
boundaries/runtime policies and one GNU-rejected declaration.

OPTIONAL CHARACTER dummies remain excluded from this specification-expression
subset. Element subscripts must use parameters or nonoptional INTEGER IN/INOUT
dummies and the existing bounded integer operations/inquiries. Local/OPTIONAL
subscript variables and sections are explicitly rejected even where GNU accepts
a descriptor-only LEN inquiry. Unallocated deferred-length CHARACTER still has
no available length and fails safely. These exclusions do not change executable
LEN's existing element/section support.

The adapter compares the retained source element name and every subscript with
the guarded expression tree. Runtime specification checks validate all element
metadata even when the actual array is empty. `test/test_character_len_elements.f90`
independently corrupts 12 descriptors at both adapter and runtime boundaries.

Fixed-length initialized scalar locals now retain [SAVE state](SAVED-LOCALS.md) across calls.
