# Bounded unlimited-repeat formats and G0

Literal formatted PRINT, external standard-output WRITE, and scalar/array-element internal
WRITE accept one final outer-level unlimited-format item, `*(...)`. The group
must contain at least one data edit, including when the I/O list is empty.
Finite groups can occur within it; another unlimited group cannot. All preceding
items retain their ordinary meaning. A repeat prefix before `*`, an item after
the unlimited group, or an unlimited group nested within a finite group is
rejected. The existing requirement for commas between format items remains.

The group repeats within the same record until its next data edit finds no
remaining I/O-list item. Reached literals and positioning are processed normally:
`(*("p",g0,"s"))` with integers 1 and 2 produces `p1sp2sp`, and with no items
produces `p`. This is distinct from ordinary format reversion, which begins a new
record and retains its previous restrictions for scalar internal and child WRITE.
A trailing X does not extend a record unless a later transfer materializes it.

Bare `G0` supports default LOGICAL, CHARACTER, INTEGER kind 4/8 and finite REAL
kind 4/8. Numeric output uses the host Fortran G0 edit at the declared REAL kind;
its exact digits/exponent spelling is processor-dependent. CHARACTER transfers
retain all characters, including trailing spaces and zero length. This increment
supports neither `G0.d` nor an exponent field. Positive-width `Gw.d` retains the
existing REAL-only subset. Derived types require the existing defined-output
path and DT descriptor; G0 does not authorize derived-object serialization.

## Bounds and failure behavior

No existing resource limit is raised:

- 64 format nodes, counting each non-outer group opening and closing separately.
- 31 nested groups and finite repeat factors from 1 through 65536.
- 65536 expanded scalar output values.
- 65536 aggregate staged formatted bytes, including separators created by
  ordinary reversion. The final external record terminator is added afterward.
- 262144 format traversal/data-transfer operations.

The parser bounds the first iteration's finite descriptor expansion; traversal,
expanded values and actual output bytes independently bound unlimited iteration.
Unlimited groups without a data edit are rejected before execution, including
runtime-sized I/O lists. Each traversal still consumes the operation budget.
All expanded item types are validated before rendering and the complete statement
is staged before external output. A failed statement emits no partial record;
previous successful statements remain visible. Internal targets retain existing
assignment-on-success behavior. Finite-value policy and the 1000000-element array
cap remain unchanged. Colon control is now supported by the separate
[colon-format extension](COLON-FORMATS.md). Slash, variable format expressions, multiple
unlimited groups and other unsupported control edits remain outside this subset.

## Evidence

`tests/unlimited_formats` has 52 source cases: 26 successful execution cases,
21 source rejections and 5 runtime boundaries. All successful cases require a
silent clean `--check`, successful GNU and candidate execution, and exact bytes
for their formatted statements. Integer/character/logical structural cases have
independent expected output as well. Only the second, originally list-directed
statement of `demo_log10` permits whitespace and finite numeric comparison; it
independently verifies 0 through 7. Its formatted first line remains byte-exact.
The comparator preserves text case, signed zero, exact integers, and nonzero tiny
values. Its 21 self-tests include adversarial output mutations.

GNU reference compilation uses `-std=f2018 -pedantic-errors -fcheck=all` and
`-ffpe-trap=invalid,zero,overflow`. GNU accepts some invalid unlimited placements
without diagnosis; those negative fixtures are compiled but never executed by
GNU, and are not counted as standard-valid or successful reference execution.
The native test adds 38 parser, producer/adapter, direct runtime-IR and format
validator assertions. The official interpreter debug profile is distinct from
the GNU reference program's `-fcheck=all` instrumentation.

The two complete M_intrinsics programs `demo_erfc` and `demo_log10` are retained
byte-for-byte from commit `fc14233036d910e3678d350efc24609e11475067`. They require
no wrappers, helper replacements or body edits. Source/license hashes and the
upstream MIT license are included in the suite. The pre-existing
`tests/grouped_formats/cases/unlimited_repeat.f90` is unchanged; only its expected
result is promoted to successful output `12`. No vendor producer changes are
needed: the adapter already binds literal format bytes to their exact source.

Relevant primary descriptions are Intel's [format specifications](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2025-1/format-specifications.html)
and [data edit descriptor forms](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2025-1/forms-for-data-edit-descriptors.html).

## Later integrated slash capability (0.49)

The exclusions above describe this feature at its original checkpoint, not the
complete 0.49 implementation. Bounded slash record editing now composes with
B/O/Z, groups, unlimited formats, colon, positioning and nonadvancing output.
Scalar internal/defined-child reached record advancement remains unsupported.
The unchanged complete BTEST demo passes all 24 records byte-exact with GNU.
Use `tests/integer_bits/run_tests.py --with-slash-formats` for the integrated
B/O/Z-plus-slash profile; `--with-boz-formats` keeps its earlier capabilities.
See [slash tests](../tests/slash_formats/README.md) for limits and evidence.

## Element-file applicability (0.50)

The same bounded formatter applies to one whole CHARACTER array element as an
internal file. It is still a single record: reached slash advancement/reversion
is rejected rather than spilling into a neighboring element. See
[INTERNAL_WRITE_ELEMENT.md](INTERNAL_WRITE_ELEMENT.md) for evaluate-once indices,
staged commit and the retained PURE, derived-output, section and substring limits.
