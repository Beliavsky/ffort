# Bounded literal CHARACTER substrings

A default CHARACTER literal can now be read with an immediate substring range:
`"0123456789"(digit:digit)`, `'abc'(:2)`, `'abc'(2:)`, or `'abc'(:)`.
Bounds are scalar INTEGER kinds 4 or 8. Omitted bounds select 1 and the decoded
literal length. Doubled delimiters are decoded before indexing. A nonempty
range must fit the base. Reversed ranges are empty, without subtracting arbitrary
64-bit endpoints. The existing 65,536-character value cap remains in force.

This supports executable expressions, PARAMETER/constant initializers, scalar
input actuals, pure/elemental procedures, FORALL and WHERE RHS expressions,
concatenation, constructors and the existing string/search intrinsics.
LEN evaluates bounds to obtain the substring length. KIND checks the complete
expression structure without evaluating bounds or invoking bound functions.
Runtime checks separately validate malformed IR, including under LEN and KIND.
Literal bases have no writable storage or alias reservation.

## Boundaries

Only an immediate literal base is added. Parenthesized literal, function-result,
array-section bases, strides, nondefault kind prefixes and writes remain
unsupported. A literal substring is not a writable actual argument.

Direct literal-substring syntax within a CHARACTER declaration length still
fails the existing independent length-text matcher. Use a supported constant
parameter as an intermediate when authoring new code; supplied original source
is never rewritten. A named INTEGER KIND selector whose value derives from
LEN of a literal substring also remains rejected by producer metadata; ordinary
integer parameter values and executable LEN are supported. Existing quoted
punctuation token boundaries, such as the
single-character literal `'['`, are unchanged. Multi-character punctuation and
escaped-quote literal substrings are tested. Ordinary functions still cannot
write mutable module state; that is not relaxed to exercise bound side effects.

Uninitialized bound values fail when evaluated, including for LEN. KIND does not
read them. An empty destination does not suppress scalar RHS length computation, so
undefined substring bounds are still rejected. An extreme reversed INTEGER(8) range is checked against the interpreter's
safety contract, not represented as GNU execution agreement, because GNU's
substring-length arithmetic may overflow at opposite endpoints.

## Original utility evidence

The supplied `xutilities.f90` uses the exact expression
`"0123456789"(digit:digit)` in `str_int`, line 2107. The focused synthetic digit
formatter retains that expression but uses a counted loop and omits optional
zero-padding; it is explicitly not an unchanged original routine.

The exact original `str_int` fixture and source provenance belong to the separate
REPEAT/control-flow work. Literal substrings alone do not make that routine run:
its REPEAT call and bare DO were outside the 0.30 subset. No complete-utilities
or complete-original-routine support claim follows from this isolated patch.

## Independent validation

`tests/literal_substrings/run_tests.py` separates strict GNU Fortran 2018
execution comparisons, deliberate source rejections, runtime-policy errors and
one interpreter-only extreme-bound safety case. The synthetic formatter,
constant/variable ranges, empty strings, escaped quotes, inquiry evaluation,
function calls and array contexts are covered.

`test/test_literal_substrings.f90` supplies 176 independent adapter/direct-runtime
checks across normal evaluation, LEN and unevaluated KIND. A separate producer
test checks six literal/range ASTs and canonical scalar CHARACTER metadata.

Vendor patch 0052 preserves the literal base and range instead of folding them
into an unrelated literal node. Existing syntax/type/range validation remains
active. It also marks the control-keyword dispatcher RECURSIVE: inline IF with
EXIT inside a procedure loop already calls that dispatcher recursively, which
was detected while running this feature's formatter under `-fcheck=all`.

The integrated 0.31 release combines this patch with REPEAT, bare DO and
token-kind-aware operator parsing. The exact original str_int and variable_names
bodies now pass their bounded GNU differential wrappers with unchanged CRLF
bytes. This does not change the full-library POINTER boundary.

Scalar array-element bases are covered separately in [ARRAY-ELEMENT-SUBSTRINGS.md](ARRAY-ELEMENT-SUBSTRINGS.md). This historical literal-base document does not define that later feature.
