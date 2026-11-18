# Runtime CHARACTER formats and nonadvancing stdout

This bounded extension admits a whole visible scalar default-kind CHARACTER
variable or dummy as a PRINT, stdout WRITE or internal WRITE format. The variable
may have fixed, assumed or allocated length. Its current defined value is copied
before output-item evaluation or destination overwrite, so internal destination
aliasing (`write(fmt,fmt) 42`) uses the original format. Literal and named scalar
CHARACTER PARAMETER formats retain their separately source-verified frozen path.

WRITE controls have fixed order: UNIT first, FMT second, then optional ADVANCE.
Positional UNIT/FMT, positional UNIT with named FMT, and named UNIT plus named FMT
are accepted. A positional FMT after named UNIT is invalid and rejected. The
stdout unit may be `*`, a verified imported OUTPUT_UNIT alias, or a whole scalar
INTEGER(4/8) name whose value is checked against OUTPUT_UNIT before format/item
evaluation. Internal UNIT may be a writable scalar CHARACTER variable or one
whole CHARACTER array element of rank one through three; it is not a whole
array, section, substring or derived-component file. The runtime format itself
remains a whole scalar CHARACTER name, not an element expression. See
[INTERNAL_WRITE_ELEMENT.md](INTERNAL_WRITE_ELEMENT.md) for independent index
validation, evaluate-once addressing and staged commit.
Names such as `fmt` and `unit` remain ordinary identifiers unless followed by `=`.

For stdout explicit-formatted WRITE only, ADVANCE accepts an unpadded literal
`YES` or `NO`, case-insensitively. Omitting it means YES. NO preserves the current
output record across subsequent statements and ordinary procedure calls. An
advancing WRITE or PRINT completes that record. Normal END/STOP does not invent
an extra newline after successful nonadvancing bytes. Trailing X positioning is
materialized for nonadvancing output, including before reversion; advancing
output retains its prior trailing-position behavior. Colon exhaustion and
ordinary/unlimited format reversion remain unchanged.

## Validation, staging and limits

The parser records a dedicated format-expression index and bounded advance mode.
The independent producer retains canonical name/control metadata; vendor patch
0082 corrects the generic WRITE factory's existing formatted flag, matching READ
0080. The adapter checks exact source declaration identity, descriptor type,
kind, rank, scope, length and absence of subobjects/call metadata. It also verifies
WRITE controls and distinguishes PRINT from a forged nonadvancing WRITE. The
runtime independently rechecks public IR, evaluates the format once and validates
its grammar before collecting items. Undefined, absent and unallocated formats
fail cleanly under the ordinary value rules. Invalid dynamic grammar, type
mismatch and internal overflow are never successful output.

Each stdout statement stages all values and its complete formatted/list-directed
text before committing. A failing statement emits no new bytes; already committed
nonadvancing bytes remain without an artificial newline. Shared pending-record
accounting prevents two separately valid formatted statements from bypassing the
65,536-character record bound. A reversion/data newline resets that accounting.
The existing 65,536 formatted staging/value limits, 64 source items, format edit
limits and 16 MiB list-directed staging cap are not raised. Final external I/O
failure is reported; no claim is made that the operating system can roll back
bytes after an actual device/write failure.

## Deliberate boundaries

No format labels, arbitrary format expressions, parenthesized names, substrings,
array-element/array formats, function-valued formats, or extra CHARACTER kinds
are added. ADVANCE variables, padded literals, internal/list-directed ADVANCE,
I/O status controls, literal/expression units, arbitrary non-stdout units and
reordered controls remain
outside this contract. Defined child WRITE keeps constant formats; parent defined
output may still use a dynamic explicit format through the normal staged path.
Existing restrictions on host scopes, mutable writes in functions, recursion and
finite numeric values remain. No new format edit descriptors are implemented.

## Original source evidence

`tests/runtime_formats/original_closure.f90` contains exact raw CRLF bytes of
xutilities `set_optional_character` (1388–1398), `integer_label` (2356–2364),
`str_real` (6482–6492), and `str_concat` (6494–6499). The module/interface/driver
and equivalent `dp` kind parameter are scaffolding. The restricted `set_optional`
generic binds the actual original helper, not a substitute. This is a focused
original routine closure, not a complete xutilities-library claim.

Complete unchanged M_intrinsics `demo_matmul.f90` is retained from commit
`fc14233036d910e3678d350efc24609e11475067`, with its MIT license. Both original
executables agree byte-for-byte with GNU compiled using `-std=f2018
-pedantic-errors -fcheck=all -ffpe-trap=invalid,zero,overflow`. The interpreter
uses its official debug profile; GNU is an independent oracle, not a backend.

The focused source suite tests success bytes, safe rejection and runtime atomicity;
native tests mutate producer/adapter/public-IR metadata independently. Runtime
policy/error cases are GNU compile-only and are not executed as unsafe oracles.
Historical fixtures are unchanged: four named-format mutable-name rejections,
four stdout WRITE control/format rejections, one formatted-array variable-format
rejection and one G0 variable-format rejection
are promoted in their manifests. The array-element format remains rejected with
updated diagnostic text. No historical result report is rewritten.

The later [runtime stdout-unit contract](../tests/runtime_output_unit/README.md)
never passes interpreted unit numbers to host WRITE or opens a native file.
The [slash extension](../tests/slash_formats/README.md) composes with runtime
formats, positioning and nonadvancing output. Reached scalar internal/defined-child
record advancement remains unsupported; a literal-known violation rejects at
checking, while a dynamic-format violation fails before statement commit.
