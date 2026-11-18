# Bounded B/O/Z INTEGER output (0.48)

PRINT, external stdout WRITE and supported scalar/array-element internal CHARACTER WRITE accept B, O and
Z data edits for effective INTEGER(4/8) items. Existing literal, named PARAMETER
and runtime formats, arrays, constructor/output implied-DOs, finite groups,
unlimited groups, colon exhaustion, ordinary record reversion, T/TL/TR and
nonadvancing records retain their existing behavior.

Supported forms are Bw, Bw.m, Ow, Ow.m, Zw and Zw.m. Width and minimum digit count
are bounded to 0..1024; width is required. A positive width requires m<=w. Omitted
m requires at least one digit. Fields are right-justified and zero-extended to m;
insufficient positive widths produce asterisks. Hexadecimal digits are uppercase.
Zero width selects the smallest positive field width. With m=0, an all-zero value
produces blanks; w=m=0 produces exactly one blank, not an empty field.

These rules follow [J3/23-007r1, Fortran 2023 draft](https://j3-fortran.org/doc/year/23/23-007r1.pdf),
clauses 13.7.2.1(6) and 13.7.2.4 (printed pp. 280 and 286–287). The standard permits
REAL and COMPLEX B/O/Z editing too; this deliberately narrower feature accepts
only INTEGER effective items. It adds neither BOZ literal parsing nor B/O/Z input,
additional kinds, input files, new format controls or larger limits.

## Declared bit width and staging

The renderer extracts the interpreter's declared 32 or 64 bits using BTEST. It
never takes ABS of a negative integer or negates the machine minimum. In
particular, INTEGER(4) negative values are not sign-extended to 64 output bits.
Octal's first partial group is bounded to the declared width. Leading zeros are
added only for the requested minimum digit count; no minus sign is emitted.

The separate output-kind guard checks INTEGER value type/kind against its output
expression before staging. Both ordinary/scalar/array collection and leaf items
inside output implied-DOs use it. A malformed public-IR value cache cannot choose
a different bit width than the declared expression. Existing legitimate INTEGER
promotion and decimal I output are unchanged. Format syntax/type association is
validated both from source and at runtime; no unchecked format reaches external
host I/O. Source format identity remains independently checked by the adapter.

Rendering reuses the existing cursor/high-water-mark machinery, preserving
backward overwrite, retained suffixes, record reversion and nonadvancing state.
All values and formatted characters are staged before statement commit. A later
format/type/cap failure does not commit a partial new record or erase prior
nonadvancing output. This is not rollback of arbitrary earlier function side effects.

Limits are unchanged: 64 format nodes, 31 nested groups, repeat count 65536,
65536 expanded values, 65536 formatted characters, 262144 format operations and
existing CHARACTER/output/work limits. Zero-width edits do not bypass runtime
character accounting. The focused suite tests the exact character limit and one
additional field, including failure after a prior nonadvancing prefix.

## GNU oracle distinction

The 89-source suite has 70 actual GNU14.2 execution agreements and 19 compile-only
references: 13 runtime guard/subset cases plus six machine-boundary observations.
Every passing execution uses byte-exact records, including zeros, blanks,
asterisks, hex case and record endings. Numeric-token normalization is prohibited.

For the processor-specific INTEGER(8) machine minimum, GNU14.2 O/Z with m=0
prints blanks instead of its nonzero high-bit representation at both -O0 and -O2.
The arithmetic value -HUGE-1 is outside Fortran's symmetric integer model, so this
is explicitly a machine-boundary/processor-specific discrepancy, not a general
standard-conformance allegation. Those unchanged sources use an independent
32/64-bit residue oracle and are only compiled in the regular GNU runner. Twelve
raw observations are retained separately. Six additional symmetric-range sources
provide actual GNU agreement for the same descriptors. Tolerances are not widened.

The 149-assertion native test checks source/adapter paths, runtime/public-IR
metadata, signed endpoints, zero/minimum digits, type failures and positioning.
The 38 adversarial runner tests check byte comparisons, silent success, named
source-located errors, generator identity and no numeric normalization.
Authoritative unchanged demo_ior/demo_not/demo_btest fixtures and combined bit
intrinsic proofs are owned by the separate INTEGER bit-intrinsic package, not
replaced here by synthetic implementations.

The unchanged demo_btest still reaches the separate unsupported slash-edit
boundary. B/O/Z support alone does not make that complete original executable.
Slash editing is not added by this patch. Combined exact demo_ior/demo_not
execution evidence is reported separately by the bit-intrinsic package.

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
