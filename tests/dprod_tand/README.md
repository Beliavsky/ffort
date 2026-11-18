# DPROD and TAND evidence

Run `python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
Either tool can run alone. The candidate is snapshotted and original source
hashes are verified before testing. Exit stages, diagnostics and stdout leaks
are checked. Numeric comparisons use Decimal, preserve signed zero and remain
exact when tolerances are zero. Run test_runner.py for 15 adversarial self-tests.

There are 67 source cases: 39 GNU executions, eight GNU compile-only cases and
20 GNU rejections. The two complete upstream programs retain exact bytes and
MIT licensing (upstream.json and UPSTREAM-LICENSE). TAND uses GNU-mode reference
flags because GNU14 implements it as an extension before Fortran 2023 mode.

verify_products.py reconstructs 144 exact binary32-widened products. Its source
and expected values cannot silently drift. verify_accuracy.py independently
computes 55 degree tangent values, including near-pole reference results, with
110-digit Decimal/Machin/sine/cosine arithmetic. Both validators run automatically
in the main source runner.

The two isolated GNU differences, near-pole accuracy and REAL4 negative-zero
sign, remain compile-only and are documented separately under oracle-limitations/.
Normal comparisons do not accept the differing outputs as alternatives. See
../../docs/DPROD-TAND.md for the bounded type/rank/domain contract.
