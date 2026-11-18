# Bounded scalar REPEAT

The supported slice is `REPEAT(STRING, NCOPIES)` with scalar default CHARACTER
STRING and scalar INTEGER(4) or INTEGER(8) NCOPIES. Both positional arguments
and the standard STRING/NCOPIES keywords, including reversed keyword order,
are supported. NCOPIES must be nonnegative; the resulting character length
must not exceed 65536. Trailing blanks are copied, not trimmed. Zero copies
and empty STRING produce an empty result. REPEAT is not elemental; arrays
are rejected. Nondefault character kinds are outside this interpreter slice.

REPEAT remains a nonreserved intrinsic name. Scalar and array variables,
function results and ordinary user procedures can shadow it. A named function
generic `repeat` first selects a matching user specific; only no match permits
falling back to the supported intrinsic signature. Ambiguity does not fall back.
See [generic/intrinsic coexistence](GENERIC_INTRINSIC_REPEAT.md) for the exact
function-only scope, source binding and keyword rules.

## Evaluation and inquiry

Constant arguments can be folded into character parameters. Dynamic counts,
assumed-length character dummies, nested REPEAT and concatenation compose
within the supported scalar subset. `LEN(REPEAT(s,n))` computes the descriptor
length without reading the character data of s; n must be defined when needed
for that length. `KIND(REPEAT(s,n))` returns the default character kind, 1,
without reading either argument's data. Neither inquiry permits structurally
invalid expression metadata. Ordinary value evaluation requires defined data.

The result-length bound is checked before allocation, with division-based
bounds checking rather than overflowing a length-times-count multiplication.
Negative counts, undefined required values, and excessive lengths fail closed.
A zero-length STRING with a huge positive count requires no huge allocation.

## Metadata contract

The interpreter call is `ex_call`, op `repeat`, args `[string,ncopies]`,
`intrinsic_mask=0`, `typ=ty_character`, `real_kind=4` (the interpreter's default
character representation), rank/extent/dims all zero. `character_len` is a
known nonnegative value at most 65536 only when NCOPIES is constant and STRING
length is known, or when NCOPIES is zero; otherwise it is -1. The independent
FortFront producer exposes TCHAR, character kind 1, rank zero. Adapter and
runtime must independently validate structural metadata and cached lengths,
including under KIND, LEN and empty-result contexts.

## Verification assets

- `tests/repeat_intrinsic/manifest.json`: independent expected answers, including
  exact formatted output that preserves blanks; no expected answer is learned
  from the candidate.
- `tests/repeat_intrinsic/run_tests.py`: GNU and/or candidate runner with source
  and executable hashes and recorded compiler versions. Use `--candidate PATH`
  and/or `--gfortran PATH`, optionally `--only REGEX` and `--result FILE`.
- `test/test_repeat_intrinsic.f90`: direct adapter, constant evaluator and
  execution mutations, repeated under KIND, LEN, concatenation, zero copies
  and empty STRING.
- `test/test_repeat_intrinsic_producer.f90`: independent FortFront type/kind/rank
  producer tests and array-name shadowing.

GNU execution is restricted to valid, initialized, bounded cases. Undefined
values and dynamic negative/huge/overlength counts are GNU compile-only.
Enormous constant repetition is skipped even at GNU compile time to avoid
constant-folding allocation hazards. Unsupported nondefault character kinds
and bounded overlength constants compile under GNU but are candidate rejects.
Compile-only and skipped cases are not evidence of matching GNU runtime
behavior. The original utility provenance fixture is maintained separately;
the 31 synthetic fixtures do not themselves claim original-routine coverage.
The separate `run_original.py` verifies retained `str_int` source lines and ten
explicit expected outputs. This original routine additionally requires literal
substring reads and bare DO, so GNU success and an isolated candidate rejection
remain recorded as historical isolated evidence. In the integrated 0.31 release, the unchanged CRLF body passes all ten explicit expected outputs against both GNU and the candidate, after literal substrings, bare DO and token-kind-aware operator parsing are combined. The full original utility library remains unsupported.

## Isolated validation

The focused differential suite has 31 cases: GNU executes 10, compiles 10
without running unsafe/undefined values, rejects 10 invalid programs, and skips
one enormous constant allocation hazard. The model-generated matrix includes
75 independently computed exact-blank results. Direct public-IR tests run 882
assertions, including 23 mutations in six contexts; eight independent producer
cases verify metadata and explicit name binding. The original-source verifier
is additional evidence and is not included in these counts.
