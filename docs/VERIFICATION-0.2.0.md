# Verification of prototype 0.2.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0 (Debian
14.2.0-19), fpm 0.13.0 alpha and Python 3.12.14. The interpreter is built with
fpm's debug profile. The independent GNU oracle uses
`-std=f2018 -pedantic-errors -fcheck=all -O0`.

## Final-source verification

- A new directory received source, tests and the pinned vendored dependency,
  excluding every build cache, object, module and executable. A full clean build
  and `python3 scripts/verify.py` passed without fetching a network dependency.
  The executable and library source, tests, vendor tree and verifier in the
  release match that clean-built source byte for byte.
- All three native Fortran test programs passed: 46 runtime contracts (32 prior
  and 14 array additions), 8 original frontend metadata compilations, 4 original
  AST/IR admission checks, and 13 array adapter checks (2 valid baselines and
  11 deliberate mismatches, including cached bounds and index types).
- The complete original independent corpus remains unchanged and passed:
  **226/226 interpreter cases** and **206/206 applicable GNU checks**, with
  20 documented interpreter-safety skips for the reference.
- The new array corpus passed **179/179 interpreter cases** and
  **156/156 applicable GNU checks**, with 23 documented reference skips.
- Combined source coverage: **405/405 interpreter cases**,
  **362/362 applicable GNU checks**, 43 explicit reference skips, no failures.
- CLI/resource tests: **17/17**. Existing harness self-tests: **18/18**.
  Array harness self-tests: **10/10**. Corpus regeneration is deterministic.
- An executable path containing spaces passed all 179 array cases using the
  command-quoting path used by the portable verifier.
- The versioned ZIP was extracted and every manifest checksum checked. It
  contains no executable, object, module, build cache, compiler or Python cache.
  Both MIT licenses and all prior independent source fixtures are retained.

The clean executable SHA-256 is
`ff1760ab57fb912678b0edc96b8694c93bb4672eee2dad4d67e15e6f8168f41f`.
It is an evidence identifier, not a distributed binary. Build paths and debug
metadata can change this hash on a new build.

## Array evidence

The 179 new cases contain 92 valid executions, 28 runtime safety cases,
23 semantic negatives, 12 syntax negatives, 18 legal unsupported boundaries
and 6 static safety checks. Forty-nine valid cases come from reproducible,
independent integer, real and logical state models (seed 20261114). Expected
values are not produced by the interpreter implementation.

Coverage includes bounds and zero extents, mixed scalar/array declarations,
all three element types, numeric conversion, per-element initialization,
storage isolation, nested indexing, scalar intrinsics, IF and counted DO,
constant bounds, exact storage limits, read/write bounds failures, index
arithmetic overflow, and atomic PRINT behavior. Twelve bounds-error cases
also require a GNU checked-runtime bounds failure.

Of the 23 new reference skips, 22 concern stronger interpreter safety policy.
One valid empty array using extreme opposing endpoints is excluded because
GNU's internal dimension-size overflow is not a useful independent semantic
oracle for that case. A skip is never counted as a compiler pass.

## Corrections and preservation

The array tests exposed a mixed-case scope-key bug in pinned FortFront:
`Values`, `vALues` and `VALUES` did not always resolve to the same array.
A two-line producer-side correction normalizes semantic scope definition and
lookup keys, leaving the original source and AST spelling intact. The patch,
provenance, MIT license and reproducer are retained. No broad upstream fix or
upstream-wide suite pass is claimed.

The adapter also handles a pinned metadata limitation: scalar array-element
occurrences can report the array's rank. It validates exact declaration binding,
declared type/kind/rank and the single scalar INTEGER subscript instead of
trusting that occurrence-rank field. Bound ASTs and cached runtime bounds are
cross-checked. See FRONTEND.md and ARRAYS.md.

Every original independent fixture and harness file is unchanged. All original
native assertions remain, with additional runtime cases. The only new change
inside the vendored library relative to 0.1.0 is the recorded scope-key patch.
The two previous metadata corrections are retained.

## Files and reproduction

- `docs/verification/0.2.0/clean-room-full-verification.log`: clean build and all checks.
- `tests/arrays/final-results.json`: final array sources, executable hash,
  compiler version, commands, outputs and case-by-case decisions.
- `tests/arrays/scalar-regression-final-results.json`: the unchanged scalar suite
  rerun against the same final clean executable.
- `tests/arrays/REPORT.md` and `README.md`: detailed test/reference policy.
- `docs/VERIFICATION-0.1.0.md` and older evidence files: retained historical results,
  not substitutes for the final 0.2.0 checks.

Use `python3 scripts/verify.py` or `bash scripts/verify.sh` on Linux. On Windows,
with Python 3, fpm and GNU Fortran on PATH, use `python scripts/verify.py` or
`powershell -File scripts/verify.ps1`. The Python entry point avoids POSIX-only
file discovery and selects the debug executable directly through fpm.

## Limits

Windows has **not** been executed or validated. No Windows binary is included.
The source and verifier are designed for portability, but this is not evidence
of a Windows toolchain pass. No complete-language conformance estimate,
performance claim, exhaustive fuzz result, hostile-input security audit, or
production-readiness claim is made. The interpreter remains a restricted,
in-process prototype with explicit unsupported boundaries.
