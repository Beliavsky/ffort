# Verification of prototype 0.6.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU reference commands use
`-std=f2018 -pedantic-errors -fcheck=all -O0`.

## Clean extraction and full verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. Every check passed.
All 1343 implementation, test, fixture, manifest, example, verifier and
vendored source inputs were compared byte-for-byte with the checked extraction
before final packaging. Only evidence/documentation was updated afterward.

- Scalar corpus: **226/226**, **206 GNU passes**, 20 explicit skips.
- Element-array corpus: **179/179**, **152 GNU passes**, 27 skips.
- Program-form corpus: **87/87**, **84 GNU passes**, 3 skips.
- Whole-array corpus: **147/147**, **121 GNU passes**, 26 skips.
- Section corpus: **183/183**, **168 GNU passes**, 15 skips.
- Module-function corpus: **89/89**, **76 GNU passes**, 13 skips.
- Combined: **911/911 interpreter cases**, **807 applicable GNU passes**,
  **104 explicit skips**, and **zero failures**. Skips are not compiler passes.
- All **11 native Fortran test programs** pass, including module frontend
  baselines plus 25 deliberately inconsistent IR cases, a module runtime baseline
  plus 12 invariant rejections and shared-budget checks, and 7 producer regressions.
- All **17 CLI/resource checks** and **75 harness self-tests** pass.

The clean debug executable SHA-256 is
`ee71cef7810b7e24b10980222263926b0cd896aedf114114ee14cea50909056c`.
This identifies the checked build, not a distributed binary. Build paths and
debug metadata can change the hash on another machine. Final ZIP extraction
and every entry in `MANIFEST.sha256` were checked after packaging.

The exact requested example, including both IMPLICIT NONE statements, is
preserved in `examples/module_functions.f90` and the module corpus. Its clean
run prints **4.59999990**, approximately 4.6. Earlier requested examples still
print **32** and **55**. The CLI reports version **0.6.0**.

## New coverage and implementation boundaries

Tests cover required positional scalar arguments, exact type/rank matching,
explicit RESULT, forward/nested calls, fresh local frames, same-named local
variables and functions in different modules, plain USE visibility, local
PARAMETER, zero-argument functions, IF/DO, scalar calls inside array indices and
sections, repeated calls and the shared work budget. Boundaries include the
16-argument, 64-function/active-frame and 16-module limits.

Static negatives include missing/extra/type-mismatched arguments, array actuals,
wrong visibility, ambiguous imports, undeclared RESULT/dummies, INTENT(IN) writes,
function I/O, module state, mutable initialized locals, optional/keyword arguments,
RETURN and recursive cycles. Runtime checks cover undefined locals/results,
argument errors, overflow, division by zero, PRINT atomicity and budget exhaustion.
The GNU runner compiles each case in an isolated temporary directory so stale
`.mod` files cannot satisfy a missing import. It does not execute undefined-value
or interpreter-specific policy cases as compiler-conformance evidence.

The adapter resolves exact function/declaration identities instead of trusting
lexical intrinsic flags or flattened symbol names. Four documented producer
changes fix resolved array-element type contamination and procedure statement
boundaries at semicolons. The strict argument checker itself is unchanged.
A separate native producer test retains four positive probes and three negative
probes, including both numeric argument-mismatch directions and trailing junk.

## Preservation and provenance

All **822 prior source fixtures** are byte-identical to 0.5.0, with no changed
prior expectations. **455 of 459 existing vendored files** are byte-identical;
the four changed source files are recorded in patch 0003 and
`verification/0.6.0/source-preservation.json`. The root and FortFront MIT licenses
are unchanged. THIRD_PARTY_NOTICES was updated to attribute the new local patch;
no upstream authorship or endorsement is implied.

The ZIP is the complete self-contained source release with pinned dependencies,
licenses, tests, examples and evidence. It excludes compilers, binaries, build
caches and Python bytecode. `MANIFEST.sha256` covers every included file except
itself. Historical versioned reports remain provenance; current results are the
six `tests/*/results.json` files and the clean-room log listed below.

Windows has not been executed. This is a portable source prototype, not a
prebuilt Windows binary, production sandbox or full Fortran implementation.
Passing this selected corpus is not an estimate of whole-language conformance.

## Evidence

- `verification/0.6.0/clean-room-full-verification.log`
- `verification/0.6.0/source-preservation.json`
- `../tests/module_functions/README.md` and `../tests/module_functions/results.json`
- `FRONTEND-MODULE-FIXES.md` and `../vendor/patches/0003-module-function-arguments-and-semicolons.patch`
- The five retained suite results under `tests/`
