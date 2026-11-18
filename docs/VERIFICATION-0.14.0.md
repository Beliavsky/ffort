# Verification of prototype 0.14.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete release candidate was archived and extracted into a fresh directory
whose path contains spaces. `python3 scripts/verify.py` built from source without
a build cache or dependency downloads and completed successfully. All final
executable source, test sources, scripts, fixtures, examples, vendored patches
and FPM configuration match that clean extraction. This report, verification
evidence copies and the file manifest were finalized afterward; no executable
source changed.

| Suite | Interpreter checks | Direct GNU checks | Weakened SIMPLE references | GNU skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| arrays | 179/179 | 152 | 0 | 27 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| independent | 226/226 | 206 | 0 | 20 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| module_functions | 89/89 | 76 | 0 | 13 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| sections | 183/183 | 168 | 0 | 15 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **2,485/2,485** | **2,284** | **80** | **121** |

There are zero failures. GNU checks include execution, compilation-only and
expected compilation rejection. Skips are not passes. The 80 weakened references
are explicitly separate from direct compiler checks of the original source.

Additional verification:

- All 27 native Fortran test programs, 17 CLI/resource contracts and 186 Python
  harness self-tests pass.
- All 108 generated nested-section programs retain their independent Python/GNU
  comparisons. The 272-value REAL32/REAL64 arithmetic matrix still matches GNU
  byte for byte.
- The new ELEMENTAL adapter regression accepts its baseline, rejects nine
  deliberate source/IR disagreements and three invalid declarations. The runtime
  regression checks overlapping rank-two assignments, empty calls and five
  malformed-IR variants, including malformed declarations on empty calls.
- The direct producer regression checks scalar/rank-one/rank-two results,
  declared result kinds, wrong argument types, same-named private module helpers,
  compound/section/keyword actuals, and composition with ordinary assumed-shape
  arguments and SUM(DIM=), including a runtime DIM.
- All 135 new independent ELEMENTAL cases pass: 85 successes, 30 invalid sources,
  nine legal but unsupported sources and 11 runtime-safety cases. The compiler
  performs 128 applicable checks, including 13 weakened SIMPLE references;
  seven interpreter-policy cases explicitly skip GNU.
- `examples/elemental_functions.f90` prints `7`, then `3 5 7 9 11 13`, then
  `1 2 10 20 30 40`.

See [the complete clean run](verification/0.14.0/clean-room-full-verification.log),
`tests/*/results.json`, the retained arithmetic/section matrix results, and
[the ELEMENTAL corpus](../tests/elemental_functions_independent/README.md).

## Scope and oracle limits

This release implements pure ELEMENTAL functions only. ELEMENTAL subroutines,
IMPURE ELEMENTAL, character/array results, optional/value dummies, ranks above
two and other unlisted language features remain unsupported. See the exact
[feature contract](ELEMENTAL-FUNCTIONS.md).

GNU Fortran 14.2 does not implement the SIMPLE prefix. Both a valid SIMPLE probe
and a forbidden SIMPLE-to-PURE call probe are recorded. SIMPLE sources are
checked against independent expectations; separately checked-in SIMPLE-to-PURE
references verify ordinary arithmetic and inherited PURE restrictions only.
They cannot validate SIMPLE's additional restrictions. No native SIMPLE,
Flang, Intel or NAG execution is claimed. Passing these selected tests does not
establish whole-language or upstream-wide conformance.

## Preservation and producer patch

All 24 prior native test sources, 21 prior examples and 2,420 prior corpus
`.f90` sources are byte-for-byte unchanged. No old case was removed. Both full
MIT licenses and all previous producer patches remain included. FPM configuration
changes only its version. Historical reports remain included, including
[0.13.0](VERIFICATION-0.13.0.md).

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
Patch 0011 corrects ELEMENTAL call-result inference, scoped metadata and argument
checking across nine producer files. Replaying it over the exact 0.13.0 vendor
tree reproduces the delivered vendor files byte for byte. It does not suppress
compiler diagnostics or add a compiler execution backend. Source execution
continues in the separate Fortran interpreter runtime.

The complete archive contains source, tests, documentation and the vendored
dependency, not compiler installations, build caches or prebuilt executables.
Windows was not executed. Existing portable Python/FPM interfaces are retained.
Every MANIFEST.sha256 entry is checked from a separate final extraction.
