# Bounded scalar CHARACTER substrings

Scalar default-CHARACTER variables, constants, dummies and local results now
support `name(lower:upper)`, `name(:upper)`, `name(lower:)` and `name(:)`.
Bounds are scalar INTEGER kind 4 or 8 expressions. Omitted bounds mean 1 and
the current declared character length. Nonempty substrings must lie within that
length; reversed bounds yield an empty string without overflowing bound arithmetic.

Substring assignment pads or truncates to the target substring length. Both
bounds and the complete RHS are evaluated before committing a write, preserving
overlapping self-assignment. An empty target still evaluates the RHS. A partial
write to an otherwise undefined scalar is deliberately rejected because this
interpreter tracks definition at scalar, not individual-character, granularity.
A full-length substring assignment can initialize a scalar, including length zero.

LEN obtains the substring length from its declared base length and evaluated
bounds without reading the base characters. KIND validates expression structure
without evaluating either bounds or base data. PARAMETER substrings are supported
in constant expressions. Runtime values can be used as input expression actuals;
nonparenthesized substring actuals conservatively reserve their entire scalar
base against any other writable actual. Writable substring actuals remain
unsupported. Existing pure/module-write restrictions continue to apply.

Literal bases are separately supported by [LITERAL-SUBSTRINGS.md](LITERAL-SUBSTRINGS.md).
Scalar substrings of rank-one/two/three CHARACTER array elements are now supported separately; see [ARRAY-ELEMENT-SUBSTRINGS.md](ARRAY-ELEMENT-SUBSTRINGS.md). This does not add substrings of array sections or function-result
bases, nondefault character kinds, scalar allocatable CHARACTER, or strides.
Existing element/storage/step limits still apply. The complete utility source is
not claimed to execute.

## Independent validation

The guarded parser and FortFront adapter independently validate the declaration
identity, scalar CHARACTER base, bound trees, absence of strides, and result
metadata. Runtime checks do not trust a successful adapter pass. Producer fixes
preserve CHARACTER lengths in grouped/module declarations and resolve a scalar
CHARACTER slice as rank zero before its substring flag has been inferred.

`tests/character_substrings/run_tests.py` checks the untouched original `strip`
body, with byte hashes and source ranges, and standalone reads, writes, overlap,
automatic lengths, elementals, FORALL reads, constants, input calls, empty values,
wide bounds, invalid syntax, undefined data and alias rejection. GNU Fortran is
only an independent oracle, never an interpreter execution backend. Opposite
int64-bound safety cases are GNU compile-only: GNU 14.2 overflows its internal
length arithmetic on those cases. Invalid/undefined behavior is also not used as
a runtime oracle. Native tests add 16 adapter and 16 direct-runtime mutations,
plus strict producer rank and length-metadata tests.
