# Verification of prototype 0.12.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU source-corpus commands use
`-std=f2018 -pedantic-errors -fcheck=all -O0` where applicable.

## Clean extraction and complete verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and built without a build cache or network dependency
downloads using `python3 scripts/verify.py`. The full command exited zero.
Final executable source, tests, fixtures, examples and build configuration match
that extraction. Current result files and the aggregate log come from this clean
run. This report and the final file manifest were finalized afterward; no
executable source changed.

| Suite | Interpreter cases | Applicable GNU checks | Explicit GNU skips |
| --- | ---: | ---: | ---: |
| Independent | 226/226 | 206 | 20 |
| Arrays | 179/179 | 152 | 27 |
| Program forms | 87/87 | 84 | 3 |
| Whole arrays | 147/147 | 121 | 26 |
| Sections | 183/183 | 168 | 15 |
| Module functions | 89/89 | 76 | 13 |
| Numerical procedures | 88/88 | 85 | 3 |
| Argument association | 145/145 | 145 | 0 |
| Rank-two arrays | 136/136 | 136 | 0 |
| Rank-two sections | 269/269 | 262 | 7 |
| Array intrinsics | 234/234 | 234 | 0 |
| Keyword arguments | 446/446 | 446 | 0 |
| **Total** | **2,229/2,229** | **2,115** | **114** |

There are **zero failures**. Applicable GNU checks include executions,
compilation-only checks and expected compilation rejections; explicit skips are
not compiler passes. The new 446-case keyword suite comprises 307 independent
output/GNU execution comparisons, 105 expected GNU compile rejections, and 34
GNU compilation-only checks (23 runtime-safety and 11 unsupported-source cases).

In addition:

- All **22 native Fortran test programs**, **17 CLI/resource contracts** and
  **153 runner self-tests** pass.
- The new keyword adapter regression accepts its baseline and rejects **28
  deliberate source/IR disagreements**. Producer regressions check keyword
  wrappers, unchanged assignments, strict mismatches, and **22 scalar/array
  conversions**, including rank-one/rank-two and nested DIM forms, plus four
  conversion type-mismatch negatives.
- **108/108 generated nested-section programs** match independent Python
  expectations and GNU execution, including bounds, empties, strides and copy-back.
- The arithmetic matrix produces **272 formatted REAL32/REAL64/mixed-kind
  values exactly matching GNU Fortran byte for byte**.
- `examples/keyword_arguments.f90` produces `4 5`, `2 -1`, `7`, and `42`, matching
  GNU. Existing implicit-main (`32`), parameter (`55`), module and Black-Scholes
  examples remain included.

See [the complete clean-run log](verification/0.12.0/clean-room-full-verification.log),
`tests/*/results.json`, the arithmetic/section matrix results, and
[the keyword corpus](../tests/keyword_arguments_independent/README.md).
The archive contains source, tests, documentation and the pinned dependency,
not build caches, compiler installations or a prebuilt executable.

## Coverage and corrected producer behavior

The keyword suite covers all ARRAY/DIM/MASK permutations across reductions and
numeric kinds; standard DOT_PRODUCT/MATMUL/inquiry names; positional prefixes;
optional DIM/MASK combinations; empty/masked and shape-only evaluation; sections;
nested expressions; module/imported/internal procedures; dummy declaration order;
16 arguments and 63-character names; INT/REAL conversions; mixed types; writable
scalar/element/section arguments; frozen destinations; aliases; copy-back and
initialization loss; conformance, overflow and work/storage limits.

Duplicate/unknown/missing arguments, positional-after-keyword forms, collisions,
wrong types/ranks/kinds and nondefinable writable actuals are rejected. A named
DIM cannot fall through to the positional MASK overload. The adapter separately
reconstructs association from the AST and accounts for every keyword wrapper.
An independent scoped source review found no additional association or skipped-
wrapper issue.

Two small retained producer patches mark expression-call keyword wrappers and
correct conversion result type/rank inference. They do not suppress diagnostics,
replace strict semantics or add an execution compiler backend. Both patches were
replayed against the previous release's vendor source and reproduce the delivered
three changed vendor files exactly. Direct producer regressions remain separate
from the interpreter adapter tests.

## Boundaries and preservation

This is a restricted interpreter prototype, not a full modern Fortran compiler
or hostile-input sandbox. Optional user dummies, KIND arguments, scalar elemental
intrinsic keyword arguments and LBOUND/UBOUND without DIM remain unsupported.
Existing rank/type/kind, alias, overflow, initialization and bounded execution
policies are unchanged. Runtime source is byte-for-byte unchanged from 0.11.0.

All 19 previous examples and all 19 previous native test sources are unchanged.
All previous source corpus fixtures are retained unchanged; 11 former keyword-
unsupported expectations were promoted to GNU-checked successes. No old case was
dropped. Both full MIT licenses are unchanged; third-party notices now identify
the added patches. FortFront remains pinned to commit
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f` with its previous patches retained.
FPM configuration is unchanged apart from the version. Historical reports remain.

Windows has not been executed; the portable source and Python/FPM interfaces are
retained. FortFront process-global state still prevents concurrent compilation
within one process. No upstream-wide test-suite pass is claimed.

After packaging, every MANIFEST.sha256 entry is verified from a separate final
extraction. Reproduce with `fpm build`, `fpm test`, and `python3 scripts/verify.py`.
