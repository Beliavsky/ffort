# Quoted punctuation is CHARACTER data

The parser's optional and required syntax consumers (`take` and `expect`) now
refuse a CHARACTER token even when its decoded text matches the requested
punctuation or keyword. Their callers request grammar, never literal data. This
fixes quoted `[` and `(` being consumed as constructor/group openers before
primary-expression token-kind dispatch, including `('/')` being mistaken for
the start of a slash-style constructor. It also rejects invalid quoted closers
such as `len('a' ')'` and `(1 ')'`, formerly accepted as if the quotes were absent.

Two direct lookaheads receive the same guard: a quoted `')'` is an actual argument,
not an empty argument list, and quoted `']'` or `'/'` is a typed CHARACTER
constructor item, not its closing delimiter. Unary/binary operators retain their
existing token-kind gates and precedence. No vendor, runtime, format-language,
name-resolution, function-signature or resource-limit change is made.

This is a bounded parser correction, not a claim of complete Fortran grammar.
The original audit separately recorded a CHARACTER-component subset rejection.
Fixed-length default CHARACTER components are now supported by the 0.49 extension;
the earlier audit outcome is historical, not the current derived-type contract.

## Evidence

The 100-case focused suite covers punctuation-only and escaped-quote literals in
scalar output, parentheses, concatenation, actual arguments and typed/untyped
constructors, plus literal substrings and defined CHARACTER `+`. It also checks
actual operators, named/literal formats, malformed pseudo-punctuation, missing
delimiters and unary type boundaries. Eighty-seven successful cases compare
exact output bytes with strict GNU Fortran; twelve malformed programs require
rejection and one valid-GNU CHARACTER-component program was a subset rejection
in that original audit. These are the historical parser-only counts. There is no whitespace/case/numeric normalization.

A new native program checks 17 punctuation spellings through recognizer,
independent adapter and runtime, plus six malformed source sequences. The four
runner self-tests require exact output and a silent successful `--check`.

Three unchanged release043 composition fixtures now execute: CHARACTER `+`
with internal READ, literal concatenation with colon/internal output and scalar
allocation, and allocated-result lifetime with READ. They remain owned by the
composition suite; no fixture body or expected output was rewritten.

## Transparent historical expectation migration

- `tests/quoted_operators/unchanged_bracket_boundary.f90` and
  `unchanged_parenthesis_boundary.f90` are byte-identical. Only their manifest
  expectations change from rejection to GNU-compared execution. Their historical
  names are retained.
- `tests/literal_substrings/reject_bracket_token.f90` likewise retains its exact
  literal-substring source bytes; only its manifest changes to GNU execution.
- `test/test_quoted_operators.f90` retains the exact embedded bracket source; its
  assertion changes from expected rejection to parser/adapter success. Its
  malformed quoted-concatenation rejection remains.
- The original release029 bracket-PRINT probe remains byte-identical. Its runner
  observation label and current README now describe the promotion instead of
  claiming a current rejection. The probe remains outside its 12 original
  composition assertions, and the separate GNU section-copyback caveat remains.
- Historical version-specific reports are not rewritten.

Reproduce:

```
python3 tests/punctuation_literals/run_tests.py --candidate /path/to/interpreter
python3 tests/punctuation_literals/test_runner.py
python3 tests/quoted_operators/run_tests.py --candidate /path/to/interpreter
fpm test --profile debug --flag '-ffree-line-length-none'
```

Isolated verification uses an app/library debug build, manual links for the new
native program and 20 relevant existing native programs, and 868 existing source
cases. The complete clean native aggregate remains the release integrator's
separate check. GNU references use `-std=f2018 -pedantic-errors -fcheck=all
-ffpe-trap=invalid,zero,overflow`; those flags do not describe the interpreter build.

## Current retained structure-actual boundary

The unchanged `structure_actual` source still rejects at 11:7 with
`Expected ), found )` in the clean 0.49 probe. Its quoted closing-parenthesis
constructor actual exposes a separate parser boundary; it is not evidence that
fixed CHARACTER fields are unsupported. The source and manifest remain unchanged,
and no execution promotion is claimed.
