# AINT, ANINT, ASINH and ACOSH focused evidence

Run `python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
Either tool may be used alone. The runner snapshots the candidate, validates
original byte hashes, verifies the independent rounding matrix, enforces exact
exit/diagnostic behavior and rejects output leaks or nonfinite output. Run
`python3 test_runner.py` for 15 harness self-tests and
`python3 verify_matrix.py` to reconstruct 208 exact rounding expectations.

There are 66 source cases. GNU 14.2 executes 24, only compiles 14 and rejects 28.
The compile-only group includes bounded unsupported features, runtime failures,
and the separately documented narrow-result rounding discrepancy. The last is
not accepted as a GNU execution agreement or an alternate answer. See
oracle-limitations/README.md and gnu14-receipt.json.

Four complete upstream programs retain exact bytes under cases/: demo_aint,
demo_anint, demo_asinh and demo_acosh. upstream.json records commit and hashes;
UPSTREAM-LICENSE retains the upstream MIT notice. No original is rewritten.

The companion native tests are test_real_round_inverse.f90 (3,012 assertions,
including public-IR mutants, direct/indirect cycles, kind consistency, NaN/Inf
execution rejection and unevaluated KIND) and test_real_round_inverse_producer.f90
(22 producer identity/type/kind/rank and nonreserved shadow cases).
The supported contract is documented in docs/ROUNDING-INVERSE-HYPERBOLIC.md.

Numeric tokens are compared as Decimal values, without a binary64 conversion.
Zero-tolerance cases preserve adjacent decimal distinctions, arbitrarily small
nonzero printed values and signed zero. Integer expectations remain exact even
when the actual token uses a decimal point. Explicit nonzero tolerances remain
available for inverse hyperbolic display rounding, but cannot erase a zero-sign
mismatch. The independent matrix restores the input sign when rounding yields
zero; its Fortran source is unchanged. The hardening receipt records adversarial
failures of the old comparator and the strict replacement's outcomes.
