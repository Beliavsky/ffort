# Verification of prototype 0.15.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete release candidate was archived and extracted into a fresh directory
whose path contains spaces. `python3 scripts/verify.py` built from source without
a build cache or dependency downloads and completed successfully. All final
executable source, native and independent tests, scripts, examples, vendored
source/patches and FPM configuration match that clean extraction. This report,
verification evidence copies and the file manifest were finalized afterward;
no executable source changed after the clean run.

| Suite | Interpreter checks | Direct GNU checks | Weakened SIMPLE references | GNU skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| arrays | 179/179 | 152 | 0 | 27 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
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
| **Total** | **2,613/2,613** | **2,391** | **83** | **139** |

There are zero failures. GNU checks include execution, compilation-only and
expected compilation rejection. Skips are not passes. Weakened SIMPLE-to-PURE
references are separate from direct compiler checks of the original source.

Additional verification:

- All 30 native Fortran test programs, 17 CLI/resource contracts and 200 Python
  harness self-tests pass.
- The 108 generated nested-section programs and 272-value REAL32/REAL64
  arithmetic matrix retain their independent Python/GNU comparisons.
- New native adapter tests exercise pure and impure elemental subroutine calls,
  exact prefix preservation and nine deliberate IR/source disagreements.
- New native runtime tests exercise successful array copy-back, empty calls,
  shared budgets, whole-reference overlap, OUT undefinedness, malformed dummy
  intent (including an empty call), forged OUT variable type binding and purity.
  An independent `-fcheck=all` review reproduced and verified the two new malformed
  IR protections before the final clean run.
- A direct producer regression checks module/internal CALL array actuals,
  rank-one/rank-two sections, IMPURE/ELEMENTAL prefix retention and rejection
  of REAL array elements against an INTEGER dummy.
- All 128 new independent cases pass, including the rank-two stride matrix,
  conformability before I/O, scalar-actual evaluation, definition flags,
  nested forwarding, impure element order, full-result caching with reductions
  and MATMUL, cache reset each DO iteration, empty calls and recursive I/O.
  GNU performs 110 applicable checks: 81 executions, 12 compile-only cases and
  17 expected rejects. Three checks use weakened SIMPLE references; 18
  interpreter-policy cases explicitly skip GNU.
- `examples/elemental_subroutines.f90` was independently compiled with GNU and
  executed by the interpreter; output values matched.

See [the complete clean run](verification/0.15.0/clean-room-full-verification.log),
`tests/*/results.json`, retained arithmetic/section matrix results, and
[the new corpus contract](../tests/elemental_subroutines_independent/README.md).

## Scope and oracle limits

This release supports ELEMENTAL subroutines and explicitly IMPURE ELEMENTAL
functions/subroutines under the exact [feature contract](ELEMENTAL-SUBROUTINES.md).
Impure functions still require INTENT(IN) dummies; writable impure-function
dummies are legal Fortran but explicitly unsupported here. Mutable module/host
state, SAVE, external file I/O, optional/value/pointer/allocatable dummies,
array/character results and ranks above two remain unsupported.

The standard's entire-reference alias and writable-array rules are checked
independently. GNU 14 accepts all-IN array subroutine references and duplicate
IMPURE despite the independent source restrictions; those fixtures are not
claimed as GNU rejection evidence. GNU can interleave nested/sibling impure
references and omit masked elements. The prototype instead materializes an
impure function reference in full, caches its result per statement occurrence,
and uses a documented shape-only inquiry policy. Relevant witnesses use GNU
compilation plus independent expected output, not misleading exact-output
comparisons. Whole-call copy-back is atomic on successful return; earlier
completed PRINT records cannot be rolled back after a runtime failure.

GNU Fortran 14.2 does not implement SIMPLE. The 83 weakened references check
ordinary arithmetic and inherited PURE restrictions, not SIMPLE's additional
restrictions. No native SIMPLE, Flang, Intel, NAG, Windows or upstream-wide
conformance run is claimed. This is a tested subset, not a security sandbox.

## Preservation and producer patch

Of the 27 prior native test files, 26 are byte-for-byte unchanged. The prior
ELEMENTAL frontend test now uses a contradictory PURE IMPURE prefix for its
negative case, rather than rejecting the newly supported IMPURE declaration.
All 22 prior examples and 2,566 of the 2,568 prior corpus source files are
byte-for-byte unchanged at their original paths. The two former unsupported
ELEMENTAL-subroutine/IMPURE-elemental-function fixtures were renamed and
reclassified as supported cases; no prior feature was deliberately removed.
The previous 135-case ELEMENTAL corpus still passes in full. See the detailed
[preservation audit](verification/0.15.0/preservation-audit.json).

Both full MIT licenses and all earlier producer patches remain included.
Historical verification reports remain available, including
[0.14.0](VERIFICATION-0.14.0.md). FPM configuration changes only the version.

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
Patch 0012 forwards ELEMENTAL metadata through the second strict CALL validation
route, retaining argument element-type checking. Replaying it over the exact
0.14.0 vendor tree reproduces all 457 delivered vendor files byte for byte.
The patch does not add a compiler execution backend or disable diagnostics.
Execution remains in the separate Fortran interpreter runtime.

The full archive contains source, tests, documentation and the vendored
dependency, not compiler installations, build caches or prebuilt executables.
Every MANIFEST.sha256 entry is checked from a separate final extraction.
