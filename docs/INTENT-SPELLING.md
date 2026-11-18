# INTENT direction spelling

Dummy declaration attributes accept `INTENT(IN)`, `INTENT(OUT)`, `INTENT(INOUT)`
and the equivalent two-word `INTENT(IN OUT)`. The two words are case insensitive,
may be separated by multiple spaces, and may span a supported free-form
continuation. Blank/comment-only intervening lines and trailing continuation
comments are supported. Tabs remain accepted by the interpreter's existing input
policy, but are not claimed as GNU-pedantic-conforming source.

The source recognizer maps either INOUT spelling to the same direction. The
FortFront producer independently canonicalizes the full attribute, and the adapter
continues to require exact declaration identity, dummy status and direction.
Runtime reads, writes, alias checks, OUT invalidation, optional forwarding and
allocatable association are unchanged. Grouped dummies and supported numeric,
CHARACTER, array, allocatable and recursive declarations compose with the spelling.

This does not accept arbitrary split words (`I NOUT`, `IN O UT`, `INOU T`), commas
between IN and OUT, reversed OUT IN, repeated direction words, empty directions,
missing parentheses, duplicate/conflicting attributes or uncontinued newlines.
Standalone INTENT statements remain outside the declaration-attribute subset, and
function dummies still require INTENT(IN).

`tests/intent_spelling` has 31 cases: 15 independent GNU executions, one compile-only
boundary, 13 GNU syntax rejections, and two interpreter-policy cases (tab whitespace
and writable aliases). A further 151 native assertions cover direct producer
canonicalization, source/AST agreement, changed-IR intent rejection and unchanged
runtime semantics. GNU is only an oracle, never an execution backend.

The original `set_offdiagonal` routine is retained byte-for-byte, including its
`intent(in out)` declaration and CRLF line endings. Its wrapper tests square,
nonsquare, empty and noncontiguous-section inputs. The runner checks the full
original source SHA-256 and exact retained body before compiling or executing.
