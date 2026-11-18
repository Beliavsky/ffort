# Verification of prototype 0.3.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0 (Debian
14.2.0-19), fpm 0.13.0 alpha and Python 3.12.14. The interpreter is built in
fpm's debug profile. GNU reference checks use
`-std=f2018 -pedantic-errors -fcheck=all -O0`.

## Final-source verification

A fresh directory received the final source, tests and pinned vendored dependency,
excluding all build caches, objects, modules and executables. A complete clean
build and `python3 scripts/verify.py` passed without fetching network dependencies.
All executable/library/test/verifier/vendor source files in the release match
that clean-built source byte for byte.

- Original scalar corpus: **226/226 interpreter cases**, **206/206 applicable
  GNU checks**, 20 explicit reference skips.
- Existing array corpus: **179/179 interpreter cases**, **156/156 applicable
  GNU checks**, 23 explicit reference skips.
- New program-form/parameter/power corpus: **87/87 interpreter cases**,
  **84/84 applicable GNU checks**, 3 explicit reference skips.
- Combined: **492/492 interpreter cases**, **446/446 applicable GNU checks**,
  46 explicit skips and no failures. Skips are not compiler passes.
- All four native test programs passed: **53 runtime contracts** (all 46 prior
  cases plus 7 parameter checks); 8 original frontend metadata compilations and
  4 original AST/IR checks; 13 existing array adapter checks; 14 new program-form
  checks (2 adapter baselines, 11 deliberate disagreements and 1 rejection of a
  mutable variable by the constant evaluator).
- **17/17 CLI/resource checks** and **53/53 harness self-tests** (18 scalar,
  10 array, 25 program-form checks) passed.

The clean executable SHA-256 is
`c10995410394da4f1384ca9d10f29e70567b94e35d1e29e3a7dd67027c6b057b`.
This identifies the checked build, not a distributed binary. Build paths/debug
metadata may produce a different hash on another machine.

## Requested regressions and semantics

The unchanged programs in `examples/implicit_main_power.f90` and
`examples/parameter_sum.f90` print **32** and **55**, respectively. The independent
corpus runs both through `--check`, normal execution and GNU Fortran.

Main programs may omit PROGRAM and IMPLICIT NONE and finish with END or unnamed
END PROGRAM. A named ending requires a matching explicit PROGRAM statement.
Variables still require declarations. INTEGER, REAL and LOGICAL scalar PARAMETER
constants use typed constant evaluation, may reference earlier parameters, and
may appear in scalar initializers, array bounds and normal expressions. Assignment
to a parameter and use as a DO control variable are rejected before output.

Integer exponentiation was already implemented using checked integer arithmetic;
the short power example was blocked by the old required PROGRAM header. Tests now
cover right association, sign precedence, negative/zero/extreme integer exponents,
integer boundaries, real mixing, overflow and invalid power domains through the
complete source pipeline. No floating-point replacement for integer powers was
introduced.

The adapter checks PARAMETER attributes, initializer trees, declaration identities
and cached values, and recognizes the pinned frontend's anonymous-main END node.
A legal identifier named `parameter` cannot reliably resolve in the pinned
frontend; it is now an explicit documented reserved-name subset boundary, with
three GNU-confirmed legal-unsupported cases. No binding check was weakened to
accept unresolved names, and no additional vendor patch was required.

## Preservation and provenance

Every one of the 405 original scalar/array source fixtures is byte-identical to
the 0.2.0 ZIP. All previous native assertions remain. One old scalar expectation,
`unsupported_no_implicit_none`, changes from rejection to success with output `1`
because that program form is now supported. Its name/source and historical result
files remain. The generator and manifest record this migration. The empty-file CLI
check still rejects input; its expected diagnostic now refers to the missing END.

The complete vendored source tree and its patch files are byte-identical to 0.2.0.
Both MIT licenses and attribution remain. The original evaluation checkout was
not edited. No upstream-wide fix or upstream-wide test-suite pass is claimed.

## Evidence and reproduction

- `docs/verification/0.3.0/clean-room-full-verification.log`: final fresh build,
  native tests, CLI/harness checks, and all three source corpora.
- `tests/independent/results.json`, `tests/arrays/results.json`, and
  `tests/program_forms/results.json`: complete final clean-run stage results,
  commands, source/executable hashes and reference decisions.
- `tests/program_forms/README.md`, `REPORT.md`, and `final-results.json`: independent
  focused review and its separately identified tested build, plus reference policy.
- `docs/VERIFICATION-0.2.0.md`, `docs/VERIFICATION-0.1.0.md`, and prior evidence:
  historical verification retained, not substitutes for this release's checks.

Run `fpm build`, `fpm test`, and `python3 scripts/verify.py`; the last command also
builds/tests the debug profile. Use `python scripts/verify.py` or the PowerShell
wrapper on Windows with fpm, GNU Fortran and Python on PATH.

## Limits

Windows has not been executed or validated. This is a self-contained source ZIP
with its pinned library dependency, not a prebuilt binary or bundled toolchain.
Implicit variable typing, array parameters, other declaration attributes and the
remaining boundaries listed in README.md are intentionally unsupported. Passing
these selected tests is not a full-language conformance estimate, security audit,
performance claim or production-readiness claim.
