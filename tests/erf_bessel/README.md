# ERF/Bessel evidence

See [the numerical contract](../../docs/ERF-BESSEL.md). This suite has 63 focused
contracts, 1,818 independent mathematical reference points, 32 runner self-tests,
and two companion native tests with 338 checks.

`demo_*.f90` contains seven complete unchanged MIT-licensed M_intrinsics programs.
Six execute. `demo_bessel_y0.f90` calls singular Y0(0), so it remains an intentional
runtime rejection; it is not a passing execution. `check_provenance.py` verifies
all seven source hashes and the upstream license. No helpers or wrappers.

Accuracy references use exact binary inputs, mpmath 1.3.0 at 120 decimal digits,
fixed seeds and independent analytic functions. Results are compared with fixed
relative, ULP or amplitude-scaled absolute budgets as appropriate. One exact GNU
14.2 REAL4 J16(8) precision difference is recorded separately; it is not accepted
as candidate/GNU mathematical agreement. No zero/nonfinite substitutions are used.

The source runner uses exact text/integer comparisons, numeric-only D/E
normalization and finite real tolerance. Successful --check must be silent.

Ordinary REAL output comparisons use Decimal arithmetic with no conversion through
binary64. Signed zeros must match; exact zero never matches a tiny nonzero token.
Explicit per-case relative tolerance remains available for ordinary nonzero REAL
results. Text and integer pairs remain exact, D/E normalization is numeric-only,
and nonfinite or binary64-overflowing output is rejected. Adversarial tests cover
values below binary64's minimum subnormal and exact tolerance boundaries.
