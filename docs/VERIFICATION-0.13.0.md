# Verification of prototype 0.13.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete release candidate was archived and extracted into a fresh directory
whose path contains spaces. `python3 scripts/verify.py` built from source without
a build cache or dependency downloads and completed successfully. All final
executable source, test sources, scripts, fixtures, examples and FPM configuration
match that clean extraction. This report, verification evidence copies and the
file manifest were finalized afterward; no executable source changed.

| Suite | Interpreter checks | Direct GNU checks | Weakened SIMPLE references | GNU skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| arrays | 179/179 | 152 | 0 | 27 |
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
| **Total** | **2,350/2,350** | **2,169** | **67** | **114** |

There are zero failures. GNU checks include execution, compilation-only and
expected compilation rejection. Skips are not passes. The 67 weakened references
are explicitly separate from direct compiler checks of the original source.

Additional verification:

- All 24 native Fortran test programs, 17 CLI/resource contracts and 171 Python
  harness self-tests pass.
- All 108 generated nested-section programs retain their independent Python/GNU
  comparisons. The 272-value REAL32/REAL64 arithmetic matrix still matches GNU
  byte for byte.
- The new adapter regression accepts its baseline, rejects 13 deliberate
  source/IR disagreements and four invalid-prefix/call sources, and accepts two
  redundant PURE/SIMPLE prefix forms. The direct producer regression retains
  SIMPLE for module and typed internal procedures and rejects SIMPLE output.
- All 121 new independent PURE/SIMPLE corpus cases pass: 56 successes, 50 invalid
  sources, 11 legal but unsupported sources, and four runtime-safety cases.
  Both typed prefix orders and all six PURE/SIMPLE/type orders are covered.
- Seventeen additional independent review probes pass, covering REAL(8) prefix
  permutations with continuations in internal/module procedures, intrinsic-name
  shadowing, and procedure calls in assignment-target subscripts. These are
  recorded separately and not added to the 2,350-case aggregate.
- `examples/pure_simple.f90` prints `6 6 6 23`.

See [the complete clean run](verification/0.13.0/clean-room-full-verification.log),
[extra review probes](verification/0.13.0/independent-review-probes.json),
`tests/*/results.json`, the retained arithmetic/section matrix results, and
[the PURE/SIMPLE corpus](../tests/pure_simple_independent/README.md).

## What SIMPLE verification does and does not prove

The installed GNU Fortran 14.2 accepts the Fortran 2023 option but rejects a valid
SIMPLE header. The new runner records both a valid SIMPLE probe and a forbidden
SIMPLE-to-PURE-call probe. The compiler is therefore not used as a native SIMPLE
semantic oracle. No Flang, Intel or NAG execution is claimed.

Original SIMPLE sources are checked against independent expected values and
standard-derived validity expectations. Checked-in SIMPLE-to-PURE references
exercise ordinary arithmetic, argument association and inherited PURE
restrictions with GNU. They cannot validate SIMPLE's additional restrictions.
Those restrictions are independently enforced by the recognizer and AST adapter,
including calls in uncalled procedures and unreachable branches.

This is a supported-subset implementation, not general Fortran 2023 conformance.
Mutable nonlocal data, procedure dummies/pointers, nested procedures, external
interfaces, COMMON/ENTRY, allocation, recursion, VALUE and internal file I/O
remain unsupported. Some are valid in full PURE/SIMPLE Fortran; see
[the exact boundary and primary references](PURE-SIMPLE.md).

## Preservation and producer patch

All 22 prior native test sources, 20 prior examples and 2,232 prior corpus
`.f90` sources are byte-for-byte unchanged. No old case was removed. Both full
MIT licenses and the complete interpreter runtime are unchanged from 0.12.0.
FPM configuration changes only its version. Historical verification reports
remain included, including [0.12.0](VERIFICATION-0.12.0.md).

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f` with all
previous patches retained. Patch 0010 adds recognition/preservation of SIMPLE,
its implied purity, and typed-header prefix retention across 20 producer files.
Replaying it over the exact 0.12.0 vendor tree reproduces every delivered vendor
file byte for byte. It does not suppress diagnostics or implement a compiler
execution backend. No upstream-wide or standalone FortFront SIMPLE conformance
claim is made.

The archive contains source, tests, documentation and the vendored dependency,
not compiler installations, build caches or prebuilt executables. Windows was
not executed. Existing portable Python/FPM interfaces are retained. Every
MANIFEST.sha256 entry is checked from a separate final extraction after packaging.
