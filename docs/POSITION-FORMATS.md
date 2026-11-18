# T, TL and TR format positioning

The existing bounded output formatter accepts Tn, TLn and TRn with a decimal
operand from 1 through 65536. They accept neither a repeat prefix nor a precision;
parenthesized group repetition remains available. This applies to existing
literal, scalar CHARACTER PARAMETER and runtime variable formats for PRINT,
stdout WRITE, scalar/array-element internal WRITE and bounded defined-output child WRITE.
It does not add input formatting, numbered external units, slash editing, wider
character kinds or arbitrary runtime format expressions.

T selects a position relative to the statement's left tab limit. TL moves left,
clamped at that limit, and TR moves right. Cursor and record high-water mark are
separate: later transfers overwrite selected positions, untouched suffixes are
retained, and skipped existing text is not replaced with blanks. Ordinary format
reversion resets the limit for the next record. Position edits do not count as
data edits for type association or the mandatory data edit in an unlimited group.

For nonadvancing stdout, the shared execution context retains the current cursor
and at most 65536 characters of already-written suffix. Subsequent statements,
including nested calls and list-directed continuation, preserve skipped suffix
characters. A statement is fully rendered and checked before its single external
write. A bounded synthesized host descriptor realizes a retained backward cursor;
user format text is not passed to external I/O. Failed statements publish no new
record bytes and preserve earlier completed nonadvancing output. Existing behavior
at program end remains unchanged: no artificial newline is added.

All existing caps remain: 64 format nodes, nesting depth 31, 65536 values, 262144
format operations, 65536 staged formatted characters including reversion newlines,
and the existing combined pending-record cap. The conservative static width/group
budget also remains; this is not unrestricted formatting. Position operands are
bounded even when an otherwise valid larger operand would never transmit data.
Internal files retain their destination-length checks. No producer/vendor patch,
registry expansion, expression kind or public instruction field is needed.

The implementation follows the position and nonadvancing-file rules in
[J3/24-007](https://j3-fortran.org/doc/year/24/24-007.pdf), sections 13.5, 13.8.1
and 12.3.4.4. The focused suite documents four GNU 14.2 discrepancies separately
from exact GNU successes; see tests/position_formats/README.md. Complete unchanged
COS/COSD demos match GNU byte-for-byte. The older degree_trig COSD boundary is
promoted by expectation-only metadata; its original source bytes are preserved.

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
