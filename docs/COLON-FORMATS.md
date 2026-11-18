# Colon edit descriptors

The colon edit descriptor terminates format control when the expanded I/O list
is exhausted. Otherwise it has no effect. Commas may be omitted immediately
before or after a colon. A colon inside a quoted format literal is ordinary
text. Repeated/consecutive colon descriptors are supported, but a repeat count
on a colon itself is not legal syntax.

This applies to supported PRINT, external stdout WRITE, scalar/array-element internal WRITE
and named scalar CHARACTER PARAMETER formats. Colon does not consume an item,
count as an unlimited group's required data descriptor, or extend the output
record. On exhaustion it suppresses later literals and positioning edits and
terminates all enclosing groups. Ordinary reversion still starts another record;
unlimited repetition remains on the same record. Scalar internal/defined-child
ordinary record reversion remains outside the subset.

The entire format is parsed and bounded before execution, including unreachable
edits after a colon. Type association is checked for every item that would be
transferred. Dynamic type and traversal failures remain statement-atomic with
no prefix output. Existing limits remain 64 format nodes, nesting depth 31,
65,536 expanded values, 65,536 output characters and 262,144 traversal operations.
A colon consumes the same bounded traversal operation as other edits. Conservative
static size bounds still apply to the entire finite first traversal, even if a
colon could suppress part of it at runtime. Slash and other previously unsupported
control descriptors are not added by this change.

The implementation is a separate runtime-format patch from DIGITS/NEW_LINE/
RRSPACING. Together they run the complete unchanged M_intrinsics demo_digits
byte-for-byte like GNU; see the intrinsic suite's explicit combined profile.

Validation: 188 focused source cases pass (176 strict GNU executions, seven
GNU compile-only cases and five compiler rejections), 36 native assertions,
and 34 adversarial exact-record runner tests. Tests cover zero/one/multiple items,
both comma-omission forms, quoted colons, trailing literals/spaces, partial nested
groups, both reversion modes, internal padding, all format/output limits and
statement atomicity. The old unlimited_formats/unsupported_colon source is
preserved unchanged and promoted from rejection to exact successful output.

References: [Intel colon semantics](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2026-1/colon-editing.html)
and [format comma rules](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2025-0/format.html).

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
