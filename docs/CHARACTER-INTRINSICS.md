# Bounded CHARACTER intrinsics

`INDEX`, `LEN_TRIM`, `ADJUSTL` and `ADJUSTR` operate on default-kind CHARACTER.
They are elemental: scalar expansion and conforming rank-one/rank-two operands
are supported, including sections and zero-sized arrays. String lengths remain
subject to the interpreter's existing 65,536-character limit; array results use
the existing element cap. No new character kind or allocation form is added.

- `index(string, substring [, back, kind])` searches from the left by default,
  or from the right when BACK is true. BACK may be scalar or conforming LOGICAL.
  Empty SUBSTRING gives 1, or `len(string)+1` with true BACK; an absent match gives
  zero. Both STRING and SUBSTRING participate in scalar expansion.
- `len_trim(string [, kind])` counts through the last nonblank character in each
  element, returning zero for empty or all-blank strings.
- `adjustl(string)` and `adjustr(string)` move leading or trailing blanks,
  respectively, while preserving the length of each element. Only blank spaces
  are shifted; a tab is not a blank. `LEN` can inquire about their descriptors
  without reading undefined data, including assumed-length empty arrays.

The four new intrinsic spellings remain valid ordinary identifiers. Local array
declarations, function results, user procedures and named generics take their
normal declaration-resolved meanings rather than being treated as intrinsics.

Positional and keyword calls are supported, including reordered keywords and
omitted BACK with a specified KIND. INDEX and LEN_TRIM return INTEGER(4) by
default and accept scalar constant KIND expressions selecting kind 4 or 8.
Other kinds, nonconstant/array/noninteger KIND, wrong argument types, duplicate
or unknown keywords, positional arguments after keywords, missing arguments,
and statically nonconforming shapes fail before output. Dynamic shape and
undefined-value failures remain runtime diagnostics.

A direct absent OPTIONAL LOGICAL scalar dummy forwarded as INDEX's BACK uses the
intrinsic default, false. A parenthesized dummy is an ordinary expression and
must be present and defined. Supported OPTIONAL LOGICAL array BACK and its absent-shape boundaries are
documented separately in [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).

## Specification expressions

The bounded procedure-local/result length and automatic-bound rules now admit
`LEN_TRIM` of a nonoptional CHARACTER INTENT(IN/INOUT) dummy or PARAMETER. A
single-argument `SUM(LEN_TRIM(character_array))` is also admitted. The inner
LEN_TRIM may specify a constant KIND. General arbitrary value-based character
specification expressions and other SUM forms are not introduced.

The exact original `quote` body at xutilities lines 3217–3222 is executed by the
new fixture, including its `character(len=len_trim(text)+2)` result. The complete
original utility source is still not executable; this feature is not evidence
that its I/O, allocation forms or all other procedures are supported.

## Independent validation

The source guard associates keywords and produces result metadata. The pinned
frontend independently derives elemental rank and INTEGER KIND from its own
argument nodes. The adapter compares those results and independently checks
operand types, shapes, kind selectors and CHARACTER length caches. The runtime
also validates this metadata for direct IR callers, unevaluated KIND/LEN
inquiries and nested zero-sized expressions before indexing argument storage.

The native tests exercise normal values and corrupt metadata in evaluated,
unevaluated and empty-array contexts. A separate producer-only test checks 22
source-derived type/kind/rank and array-shadowing results, including kind 16 metadata remaining
visible to the producer while the interpreter rejects it.

## Verification

Run `fpm test --profile debug` and:

```sh
python3 tests/character_intrinsics/run_tests.py \
  --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The focused suite has 37 cases, with exact blank-preserving checks and independent
expected values. It verifies original-file and normalized retained-body hashes.
GNU Fortran 14.2 executes 16 cases and rejects 17 malformed sources; three cases
are compile-only because they cover undefined values or interpreter-specific
kind limits. One valid case, descriptor inquiries around ADJUSTL/ADJUSTR on an
assumed-length empty array, triggers a GNU compiler segmentation-fault ICE. Its
exact compiler diagnostic/status is recorded separately, and interpreter output
is checked against the independently expected `5 5 0 0`, not described as a GNU
execution pass.

The shared character-search path also supports [SCAN and VERIFY](CHARACTER-SEARCH.md),
with their own independent tests and utility-expression provenance.
