# Verification of prototype 0.16.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete release candidate was archived and extracted into a fresh directory
whose path contains spaces. `python3 scripts/verify.py` built from source without
a build cache or dependency downloads and completed successfully. Every final
executable source, native/independent test, script, example, vendored file/patch
and FPM configuration matches that extraction. This report, evidence copies and
manifest were finalized afterward; no executable source changed after the run.

| Suite | Interpreter checks | Direct GNU checks | Weakened SIMPLE references | GNU skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| arrays | 179/179 | 152 | 0 | 27 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
| independent | 226/226 | 206 | 0 | 20 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| sections | 183/183 | 168 | 0 | 15 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **2,785/2,785** | **2,558** | **83** | **144** |

Zero failures. GNU checks include execution, compilation-only and expected
rejection. Skips are not passes. Weakened SIMPLE-to-PURE checks remain distinct
from direct compiler checks of the unchanged source.

Additional checks:

- All 35 native Fortran test programs, 17 CLI/resource contracts and
  220 Python harness self-tests pass.
- All 108 generated nested-section programs and the 272-value REAL32/REAL64
  arithmetic matrix retain independent Python/GNU comparisons.
- Both requested mean programs are included unchanged and executed. Constructor
  initialization prints 20. RANDOM_NUMBER fills 1,000 REAL64 values and prints
  0.49829835148774992 with this release's documented deterministic stream.
- 172 new independent cases pass: 167 applicable GNU checks,
  including 99 executions, 32 compilation-only
  checks and 36 expected rejections. 5
  runtime-policy checks intentionally skip GNU.
- New coverage includes KIND without data evaluation; constant and runtime
  constructors; numeric conversion, shape, empty-item and limit checks;
  RANDOM_NUMBER scalar/rank-one/rank-two/section/dummy behavior; range and
  loose statistical smoke tests; deterministic stream traversal across separate
  executions; nested descriptor RNG calls and empty calls.
- Native tests check 23 deliberate adapter/source disagreements, raw producer
  nested-constructor and kind metadata, malformed runtime IR, shared budgets,
  per-execution seed reset, nested-stream forwarding and RNG rollback. An
  independent checked-build review reproduced and confirmed fixes for malformed
  KIND metadata and reentrant RNG calls during section-bound evaluation.

See [the complete clean run](verification/0.16.0/clean-room-full-verification.log),
`tests/*/results.json`, and [the new corpus](../tests/mean_programs_independent/README.md).

## Scope and oracle limits

See [the exact feature contract](MEAN-PROGRAMS.md). This is still a deliberately
restricted interpreter, not a complete Fortran processor or a security sandbox.
Constructors are homogeneous numeric/logical scalar/rank-one lists. Typed/empty
constructor syntax, implied DOs, rank-two items, CHARACTER constructors and array
PARAMETER declarations are not supported. Main-program initialization does not
add procedure-local SAVE semantics.

REAL selectors admit literal/named kind parameters and direct KIND inquiries in
ordinary declarations. Typed function headers retain literal/named selectors.
Other selector expression forms are rejected explicitly; GNU compilation proves
those retained test fixtures are legal but unsupported, not interpreter defects.

RANDOM_NUMBER uses a fixed per-execution Park-Miller seed and shared nested state.
GNU's random sequence is not compared for equality. Range, variability, stream
order, reproducibility and preservation checks are independent contracts. Loose
statistical checks do not establish distribution quality or suitability for
cryptography. No RANDOM_SEED/RANDOM_INIT API is claimed.

GNU 14 does not implement SIMPLE. The 83 weakened SIMPLE references test
arithmetic and inherited PURE restrictions, not native SIMPLE conformance.
Windows, other Fortran compilers and upstream-wide test suites were not run.
Forced allocation failures and exhaustive malformed-IR fuzzing were not tested.

## Preservation and provenance

All 2,752 prior Fortran test/example sources are retained byte for byte. Four old
constructor/initializer fixtures are now correctly classified as successful;
source text is unchanged. See [the preservation audit](verification/0.16.0/source-preservation.json).
Historical reports through [0.15.0](VERIFICATION-0.15.0.md) are retained.

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
Patches 0013 and 0014 repair nested legacy-constructor speculation and KIND
selector/type metadata. Replaying both on the exact 0.15.0 vendor tree reproduces
all 457 delivered vendor files byte for byte; see [replay evidence](verification/0.16.0/vendor-patch-replay.json).
Execution is still handled only by the independent Fortran interpreter runtime.

The archive contains complete source, tests, docs and the vendored dependency,
not build caches, compiler installations or prebuilt executables. Every final
MANIFEST.sha256 entry is verified from a separate extraction.
