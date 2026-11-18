# Quoted operator tokens remain CHARACTER data

The expression parser now dispatches unary signs, `.NOT.` and defined unary
operators only for operator-kind tokens. Its binary loop likewise refuses to
interpret a quoted string as an operator. CHARACTER data such as `"-"`, `"+"`,
`'.not.'`, `'.flip.'` and `'//'` therefore remains data in assignments,
concatenation, comparisons, constructors, constant declarations, input arguments
and literal substrings. Actual numeric/logical/defined operators keep their
existing precedence and type checks.

This also closes malformed-source acceptance such as `'a' '//' 'b'`, where a
quoted pseudo-operator must not replace a real concatenation token. Version 0.43
also distinguishes quoted delimiter spellings from grammar in primary parsing,
argument lookahead and typed constructors; the prior `[` and `(` boundaries are
now successful literals. See [PUNCTUATION-LITERALS.md](PUNCTUATION-LITERALS.md).
No vendor code or runtime semantics changes are included.

## Original routine verification

With the companion REPEAT, literal-substring and bare-DO features, this correction
allows the unchanged original `str_int` line
`if (i < 0) ch = "-" // trim(ch)` to execute. The existing REPEAT suite owns its
byte-exact original body and provenance; no duplicate or rewritten routine is
introduced here. `tests/repeat_intrinsic/run_original.py` verifies ten expected
outputs against strict GNU Fortran, including negative/padded/prefixed values.

The existing `tests/release031_integration` provenance check also verifies the
unchanged `variable_names`, `str_int` and `default_integer` bodies and compares
its wrapper with GNU. Only those named bodies are original; the module/interface
and drivers are synthetic. Full original utilities execution remains unclaimed.

## Tests

`tests/quoted_operators/run_tests.py` supplies 21 cases: 15 GNU execution comparisons
and six required rejections. `test/test_quoted_operators.f90` independently checks
that five quoted spellings remain CHARACTER literal IR rather than unary/user
calls, verifies them against the producer, executes them, rejects a quoted pseudo-operator and verifies the promoted bracket
literal. Existing original source files remain byte-for-byte unchanged.
