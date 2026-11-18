# Verification of prototype 0.17.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete candidate was archived and extracted into a fresh directory whose
path contains spaces. `python3 scripts/verify.py` built from source without a
build cache or dependency downloads and completed successfully. All executable
source, native tests, corpus source, verifier scripts, examples, vendored source
and FPM configuration in the final ZIP match that tested extraction. Verification
reports, result copies and the file manifest were finalized afterward.

| Suite | Interpreter checks | Direct GNU checks | Weakened SIMPLE references | GNU skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| arrays | 179/179 | 154 | 0 | 25 |
| derived_date_independent | 73/73 | 73 | 0 | 0 |
| derived_select_integration | 18/18 | 18 | 0 | 0 |
| derived_types | 43/43 | 38 | 0 | 5 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **3,126/3,126** | **2,877** | **83** | **166** |

Zero failures. GNU checks include execution, compilation-only and expected
rejection. Skips are not passes. The 83 SIMPLE-to-PURE references are explicitly
weakened comparisons, not native GNU support for Fortran 2023 SIMPLE.

Additional checks:

- All 45 native Fortran test programs, 17 CLI/resource contracts and
  277 Python harness self-tests pass.
- All 108 generated nested-section programs and the 272-value REAL32/REAL64
  arithmetic matrix retain independent Python/GNU comparisons.
- The exact priority month-date and SELECT CASE examples run unchanged, with
  stdout byte-identical to GNU Fortran. The date suite adds 73 exact-source and
  derived cases, including negative dates/STOP, large offsets and comparisons.
- The exact REAL64 `mean(x), mean(x**2)` program runs unchanged. The 49-case
  argument-expression suite also checks real-kind/rank rejection, sections,
  empty arrays, expression/intrinsic composition and mutable dummy restrictions.
  Native producer and adapter mutations test metadata independently.
- The exact 100,000-element RANDOM_NUMBER/minimum/maximum/mean program runs with
  the default work budget. The 30 cap-driven probes read `max_array_elements`
  from source and check at/above-cap storage/results/calls, large integer bounds,
  RNG recurrence/repeatability, and independent source/CHARACTER/PRINT/work caps.
- SELECT, CHARACTER, derived operators/components/results, wide INTEGER and
  PARAMETER cache interactions have additional cross-feature coverage.

See [the complete clean run](verification/0.17.0/final-clean-room-full-verification.log),
[the machine-readable summary](verification/0.17.0/final-summary.json),
[exact-program evidence](verification/0.17.0/exact-programs.json), and
`tests/*/results.json`. Each suite records the candidate executable SHA-256.

## Scope and oracle limits

This remains a deliberately restricted interpreter, not a complete Fortran
processor or security sandbox. See [derived types](DERIVED-TYPES.md),
[SELECT CASE](SELECT-CASE.md), [INTEGER kinds](INTEGER-KINDS.md),
[array resource configuration](ARRAY-LIMITS.md), and
[array-expression argument tests](../tests/array_expression_arguments/README.md).

The requested later scalar-derived month-date program is supported. The earlier
CLASS/type-bound/defined-I/O example is not: this release does not claim CLASS,
extension/inheritance, polymorphism, type-bound procedures, defined derived I/O,
arrays of records, nested fields or default component initialization. Scalar
record fields are INTEGER/REAL/LOGICAL. Wide INTEGER DO bounds/variables remain
explicitly unsupported. Fixed CHARACTER and its documented scalar dummy/result
subset do not imply general CHARACTER arrays or allocatable strings.

The default array cap is 131,072 elements. Edit the single `max_array_elements`
constant in `src/fi_ir.f90` and rebuild to change it. This is a per-region/frame
cap, not an OS-wide memory limit. Source bytes, CHARACTER length and expanded
PRINT values remain separately bounded at 65,536; default execution work remains
1,000,000 steps. A larger cap may need more work budget and considerably more
memory because interpreted elements are tagged values rather than packed reals.

RANDOM_NUMBER retains the documented deterministic per-execution Park-Miller
stream. GNU's RNG sequence is not compared for equality. Independent recurrence,
range, repeatability and summary sanity checks are not a proof of distribution
quality or cryptographic suitability. Runtime safety/undefined-behavior probes
are not executed by GNU when unsafe; each skip is recorded in its suite.

Windows, other Fortran compilers and upstream-wide test suites were not run.
Forced allocation failures and exhaustive malformed-IR fuzzing were not tested.

## Preservation and provenance

All 2,896 prior program-corpus and example Fortran sources are byte-identical to
0.16.0. Of 35 prior native tests, 34 are also byte-identical; one malformed-IR
boundary test now uses `max_array_elements + 1` instead of hardcoded 65,537.
That is the sole change among 2,931 prior Fortran test/example files. All prior
native tests remain present and execute. Nineteen existing corpus expectations
were updated for newly supported language features or the increased array cap;
no corresponding program source was changed. See the
[preservation audit](verification/0.17.0/source-preservation.json) and
[native-test adaptation](verification/0.17.0/native-array-limit-test-adaptation.patch).
Historical reports through [0.16.0](VERIFICATION-0.16.0.md) are retained.

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
New replayable patches 0015–0020 repair nested SELECT extraction, derived
constructor/operator/type visibility and source positions, continued STOP
physical positions, declaration-resolved argument expression typing, USE-associated
array bindings, and complete logical declaration initializers.
Applying them with zero fuzz to the exact 0.16.0 vendor tree reproduces all 457
vendored files byte for byte. The pinned source, patch descriptions, FPM path
dependency, MIT licenses and attribution are included. See
[patch replay evidence](verification/0.17.0/vendor-patch-replay.json).
