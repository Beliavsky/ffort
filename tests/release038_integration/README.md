# Release 0.38 independent composition verification

This bounded suite adds 26 source cases: 23 independently authored synthetic
programs and three complete unchanged M_intrinsics programs. It composes
ISO_FORTRAN_ENV aliases, ERFC_SCALED, two-argument ASSOCIATED and CSHIFT,
without claiming complete-library or unrestricted Fortran support.

## Independent expectations

The integer shifts, ordered target-cell mappings, shapes, text records and logical
values are independently specified. ERFC_SCALED expectations are calculated from
exact binary32/binary64 inputs using mpmath 1.3.0 at 120 decimal digits. The
normal-domain formula is exp(x*x)*erfc(x). Huge positive arguments use the first
three alternating asymptotic terms; the omitted next term is far below one ULP.
No expected result is captured from the candidate or GNU.

All numeric records, including the unchanged moderate ERFC_SCALED example, must
satisfy fixed 2-ULP binary32 / 4-ULP binary64 budgets. Safe GNU executions must
satisfy the same independent expectation, and the candidate/GNU difference must
also fit that same fixed ULP budget. There is no generic relative/absolute relaxed
comparator. Numeric token count and order are exact; nonfinite tokens and zero
for a positive subnormal are rejected. CHARACTER records, logical markers and
integers are compared byte-for-byte.

The endpoint composition separately checks HUGE positive arguments, whose result
is a nonzero subnormal, and the last finite negative input for both kinds. The
native test checks the next more-negative representable input is rejected. The
focused feature's broader 439-input accuracy study, its 11 GNU14 endpoint
Infinity/zero discrepancies and observed 0.5/2.143-ULP maxima are separate evidence,
not this bounded suite's coverage or a universal error theorem.

## GNU classification and preserved boundaries

GNU 14.2 staging has 13 safe executions, 11 compile-only cases and two clean
compile rejections. Compile-only cases are never called runtime agreement:

- Undefined pointer status, expired owner lifetime, uninitialized SHIFT and
  overflowing ERFC_SCALED exercise deterministic candidate safety policy.
- Metadata-only KIND inquiries must not read undefined values or evaluate a
  value-domain error.
- The absent whole nonpointer OPTIONAL TARGET case is spec-only. Under Fortran
  2018 15.5.2.12p4, 16.2.1p2 and 16.9.16p5 the absent argument is omitted. GNU14
  has a known false/crash discrepancy, so this test is never executed with GNU.
- A valid empty selected axis with vector SHIFT is retained exactly. GNU14
  materialization fails with runtime size error at both -O0 and -O2; the standalone
  reproducer and captured receipts are in oracle-limitations/. This is distinct
  from SIZE inquiries, which GNU can answer without materializing the array.
- REAL128 is an imported unsupported-kind sentinel (-1), not REAL16 execution.
  GNU14 returns 16 for the inquiry and has its own explicit expected record.
- Rank-three CSHIFT remains unsupported even though ERFC_SCALED accepts rank3.
- Same-valued conflicting remote aliases are rejected by the candidate; GNU14
  accepts that source, so this is a compile-only candidate-boundary assertion.

## Cross-feature and native coverage

The source tests cover aliased kind declarations and keywords, rank-two per-row
shifts, INTEGER8 extrema without negation or addition overflow, fixed CHARACTER
padding, LOGICAL shape, empty arrays, source-defined intrinsic-name shadowing,
KIND value suppression and pointer-target identity around staged assignments.
Same owner with a different ordered element mapping must compare false. Initial
ASSOCIATED checks run before any target element is defined, proving no pointee
value read. Error cases require exactly the completed 'before' record and no
partial next record; check-time failures require no stdout.

The native test includes exact promoted IEEE-bit checks for CSHIFT signed-zero
and least-subnormal permutations in both REAL kinds, without numeric tolerance. It
first establishes a valid composed program and then independently
mutates public IR for each feature. It checks adapter validation separately from
direct execution, verifies exact remote import identity rather than numerical
kind coincidence, and constructs source-free CSHIFT(ERFC_SCALED(...)) roots.
KIND and shape evaluation must reject malformed descendants. Every malformed
family has a valid baseline; no rejection is counted merely because the baseline
itself is broken. The parent build owns native registration and execution.

## Original-source preservation

original/demo_associated.f90 (529 bytes), original/demo_cshift.f90 (857 bytes)
and original/demo_erfc_scaled.f90 (172 bytes) are complete untouched programs
from M_intrinsics commit fc14233036d910e3678d350efc24609e11475067. All comments,
continuations, whitespace and original program structure remain byte-identical.
The MIT license is retained. There are no source excerpts, wrappers or substituted
helpers. Sizes and hashes are pinned independently in both the provenance map and
runner, so changing an original and forging its map hash fails verification.
Historical fixtures and the old F90 baseline are untouched.

## Reproduction and current verification status

Run test_runner.py for the 42 adversarial harness self-tests. Run run_tests.py
with --gfortran /absolute/path/to/gfortran and/or --candidate pointing to a completed
immutable executable. The runner snapshots and verifies the candidate hash,
pins all source/manifest bytes before and after execution, applies timeouts,
rejects signals/backtraces and unexpected stderr, and records explicit exit codes.
A clean generator replay reproduces every synthetic source and its manifest.

The immutable merged candidate passes all 26 source cases with zero integrity
failures, and GNU staging plus 42 harness self-tests pass. The focused native
target passes 429 independent assertions with exit status zero. receipt.json
records these completed focused checks separately from final clean verification.
combined-results.json preserves focused evidence; the final clean-release run will
write results.json separately. The first-run scaffold failures are retained in
initial-scaffold-results.json. The two initial native scaffolding/API expectation
failures are preserved under initial-evidence/, alongside the final native log.

Initial synthetic drivers used unsupported exponent-width FORMAT syntax, omitted
required explicit INTENT on dummy arguments, printed a completion marker after
an already-rejected pointer escape, and expected a different duplicate-keyword
diagnostic. Drivers now use list-directed numeric output with the same strict ULP
oracles, explicit INTENT(IN), the completed marker before escape, and the exact
reported diagnostic. The lifetime probe verifies escape rejection at owner-scope
return, before the later ASSOCIATED inquiry. The native alias adapter probe now
clears the preceding intentionally failed diagnostic before its independent call.
Its source-free shape baseline now expects the public API's prepared descriptor
[3,1,1], while cached rank-one IR dimensions remain zero. No rank, extent or
descendant mutation rejection was removed.
No original bytes or mathematical, shape, mapping, state, or safety expectation
were changed.
