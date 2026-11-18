This historical suite report is retained for provenance. Current release results
are in `results.json` and `../../docs/VERIFICATION.md`.

# Independent interpreter verification

## Final result

**226 of 226 independent interpreter cases passed.** Each case was exercised in
both `--check` and execution mode on the rebuilt FortFront-integrated debug CLI.

GNU Fortran 14.2.0 independently passed **206 of 206 applicable baselines** with
`-std=f2018 -pedantic-errors -fcheck=all -O0`. Another 20 cases test stronger
interpreter safety rules and intentionally do not use GNU behavior as an oracle.
The evaluator itself passed all **18 self-tests**.

- 139 valid programs matched expected outputs, including 100 deterministic
  generated arithmetic expressions (60 integer, 40 real32; seed 20261114).
- 22 malformed programs were rejected, including `x=(1+)`, incomplete operands,
  invalid adjacent signs, trailing tokens, unmatched constructs, and program names.
- 28 semantic negatives were rejected, including incompatible assignments,
  undeclared names, invalid operators/conditions, illegal DO-variable mutation,
  wrong intrinsic arguments, and invalid constant initializers.
- 17 unsupported cases failed before executing earlier statements.
- 18 runtime failures passed static checking and then failed with exit 2 and a
  diagnostic: uninitialized reads, integer overflow, division by zero, non-finite
  real results, invalid conversion, zero DO step, and execution budget exhaustion.
- 2 overflowing constant initializer cases failed statically as required by the
  prototype safety contract.

DO verification includes positive and negative strides, zero iterations, final
control values, non-unit overshoot, bounds and step evaluated once, nesting, and
sequential reuse. Numeric checks include integer division toward zero, power and
unary precedence, right-associative exponentiation, integer negative powers,
real32 literal and expression rounding, and conversions. PRINT checks include
empty lines, quotes/comments, and adjacent character fields.

## Defects caught and rechecked

The first integrated run of the then-220-case suite passed 215. It rejected legal
bare `PRINT *` and incorrectly deferred four invalid constant initializer checks
to execution. The implementation corrected those paths. A subsequent reviewer found remaining
grammar/name-collision gaps; the corpus added invalid repeated NOT, a variable
sharing the PROGRAM name, an intrinsic sharing the PROGRAM name, and a valid
parenthesized double-NOT control case. The final 226-case run verified all these
regressions against the rebuilt executable. The former 222-case pass is preserved
as `intermediate-222-results.json`, not the current final result.

`initial-candidate-results.json` preserves that earlier result. The authoritative
current record is `final-results.json` and its readable `final-summary.txt`.
`baseline-results.json` contains the separately recorded GNU-only baseline.

## Exact recorded artifact

- Executable SHA-256: `c87d87977527be310f479fd25001faacd51449f6ab6304487216623b412c19e4`
- Corpus manifest SHA-256: `be645d4e45e8c15a7e8900f4004442823dde33f72a30b37b9019854f32eb0bb7`
- Runner timestamp: `2026-11-14T03:53:59.252469+00:00`

Every source SHA-256, command, exit status, stdout, stderr, and test decision is
recorded in `final-results.json`. See `README.md` for reproduction commands and
`make_corpus.py` for independently authored/generative oracles.

## Interpretation and limits

This is a bounded prototype regression result, not whole-Fortran conformance or
production-readiness certification. The generated sweep is deterministic and
small. Output whitespace is normalized except explicit blank-line checks; numeric
comparisons allow ordinary real32 printing roundoff. No exact diagnostic wording
or source-location accuracy is asserted. Unsupported constructs and reserved
keyword/intrinsic identifiers are documented prototype restrictions, not claims
that such Fortran is invalid. The corpus is independent of implementation code,
but it is still a selected test suite rather than exhaustive verification.
