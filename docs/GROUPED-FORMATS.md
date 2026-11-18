# Bounded parenthesized format groups

Literal formats accept comma-separated parenthesized groups, optionally preceded
by a positive repeat count: `(a,2(1x,a),' =',2(1x,i0),a)` and nested groups such as
`(2("[",2(i2),"]"))`. Groups use only the already supported descriptors and quoted
literals. Parentheses, commas and doubled quotes inside literals remain literal
characters. Empty groups and omitted commas are not supported.

Groups apply to PRINT, the supported stdout WRITE form, scalar/array-element
CHARACTER internal WRITE and existing defined-output child WRITE. Group support does not introduce
new unit numbers, control specifiers, dynamic formats, FORMAT labels, slash,
colon, positioning, other descriptor letters or DT parameter lists. The later
bounded unlimited-repeat and G0 extension is described in [UNLIMITED-FORMATS.md](UNLIMITED-FORMATS.md).

On format reversion, a new record begins at the opening parenthesis matching the
last closed group before the outer closing parenthesis, including that group's
repeat count. Processing then continues through any following edits. If there
is no inner group, the existing whole-format reversion applies. A nested group
inside the last top-level group does not replace its enclosing group's reversion
point. Exhausting the data list stops at the next data descriptor or format end,
so reached literals are emitted and unreached trailing literals are not.
A reversion segment without data descriptors fails if items remain. Internal
scalar-file and defined-output child writes continue to reject reversion.

## Bounds and staging

- A format program contains at most 64 nodes. A descriptor or quoted literal is
  one node; each group's opening and closing parentheses are one node apiece.
  The outer pair does not count. Consequently, nesting is limited to 31 groups.
- Each finite group or descriptor repeat count is from 1 through 65,536. Groups are
  represented without expanding their repetitions in memory.
- Repeated fixed widths, positioning blanks and literal lengths are checked
  against the existing 65,536-character full-cycle bound using checked products.
  Actual formatted statement bytes, including record separators, retain the
  65,536-character aggregate cap. Surplus trailing X edits still do not extend
  an output record unless followed by a transfer.
- Group traversal and data edits share the existing 262,144-operation bound.
  Repeated zero-length literals or nested no-data groups cannot loop unboundedly.
- Known shapes undergo complete static type checking, including the correct
  reversion segment. Dynamic shapes undergo the same checks before runtime
  rendering. A failed statement produces no partial stdout and cannot commit a
  partial internal CHARACTER target.

## Verification

Run `python tests/grouped_formats/run_tests.py --candidate PATH --gfortran gfortran`.
The suite fixes independent expected bytes before running GNU Fortran with
`-std=f2018 -pedantic-errors -fcheck=all`. GNU is run only for supported positive
cases; invalid or potentially nonterminating no-data formats are checked solely
against interpreter rejection contracts. Coverage includes the literal format
used by the original `assert_le` utility, nested and last-group reversion,
empty arrays, reverse rank-two sections, internal records, quoted punctuation,
dynamic association, malformed groups, and exact/over-limit boundaries. Native
`test_grouped_formats` adds adapter/runtime mutation and direct validator checks.
Existing flat formatted-array regressions remain part of verification; their
formerly rejected valid grouped source is now an accepted differential case.

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
