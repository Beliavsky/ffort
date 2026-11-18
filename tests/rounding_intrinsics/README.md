# Rounding and LOG10 checks

Run `fpm test --profile debug --target test_rounding_intrinsics`, then
`python3 tests/rounding_intrinsics/run_tests.py --candidate PATH_TO_INTERPRETER`.
The Python suite checks GNU Fortran successes, GNU-invalid source rejection,
legal-but-unsupported boundaries, and interpreter-only checked runtime guards.
Undefined/overflow/domain-error GNU programs are compiled but not executed.
INTEGER output is compared exactly, including INTEGER(8), not through floating
point. Results record the candidate binary hash and individual tool output.

`utility-provenance.json` records untouched source SHA-256, normalized original
line ranges and hashes for floor_10/ceiling_10. Only module wrappers and drivers
are new. This is not a full-file utility execution claim.
