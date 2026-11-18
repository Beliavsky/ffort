# ASCII lexical comparisons

Run from the repository root:

```sh
python3 tests/lexical_comparisons/test_runner.py
python3 tests/lexical_comparisons/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
```

The four intrinsics LGE/LGT/LLE/LLT accept default CHARACTER strings, use ASCII
ordering and pad the shorter argument with blanks. Results are default LOGICAL.
Each family has scalar, array, matrix/cube assignment, strided and substring,
empty-array, keyword STRING_A/STRING_B, constant, KIND non-evaluation, OPTIONAL,
allocatable CHARACTER, WHERE, loop and nonreserved-name tests. Independent
integer-code oracles cover every pair of ASCII codes 0 through 127 and every
one-character code against a blank-padded zero-length string. Prefixes with
embedded NUL/control characters are covered through those ordinary CHAR values.

The four complete unchanged M_intrinsics demos retain their upstream hashes and
MIT provenance. All output records, including the five formatted ASCII rows and
list-directed results, must match GNU bytes exactly for all four originals. Other
fixtures require exact tokens unless marked as exact records; no numerical
tolerances are used. No source rewrite, helper replacement or shortened original is used.

Nondefault CHARACTER kinds are rejected by both candidate and strict GNU. Values
outside ASCII 0:127 are deliberately outside this bounded implementation and use
GNU compile-only evidence. Undefined-value and work-budget errors likewise are
not claimed as GNU execution agreements. Each compared character consumes the
existing execution budget, including suffixes after the first unequal character;
that both validates the full repertoire and bounds work. No resource cap changes.

The runner rejects whitespace-only successful stderr/check stdout and empty-output
leaks. Its standalone self-tests preserve exact formatted prefix bytes, exact
Decimal distinctions, signed zero handling and unique registry identities.

## Recorded isolated validation

169 source cases pass: 112 successful GNU execution comparisons,13 GNU compile-only
runtime-boundary cases and44 matching source rejections. All four complete original
programs have byte-exact GNU output agreement. There are 29 harness self-tests and 20
independent producer cases. The directly linked native program passes 134,127
assertions: 3,055 structural/metadata/inquiry checks plus 131,072 assertions over all
65,536 family/code-pair combinations. Six related source suites pass 442 cases.
No isolated full FPM native aggregate was run; integration owns that release check.
