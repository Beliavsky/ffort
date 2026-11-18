# PURE internal-WRITE classification correction

Run `python3 tests/pure_internal_write/run_tests.py --candidate /absolute/path/to/interpreter`
and the auto-discovered native `test_pure_internal_write`. The source runner
compares successful output byte-for-byte with independent strict GNU F2018
execution. Negative or intentionally bounded cases are compile-only GNU checks.
The native program tests the producer directly, so earlier source-guard rejection
cannot hide an external-unit classification error.

The retained diagnostic_minimal.f90 is a labeled reduction of the unchanged
release044 composition fixture: only the outer dynamic-format implied-DO is
replaced by a literal-format scalar call. Certified0.43 rejects that reduction
with the same PURE WRITE error as preview4580cb5e. This establishes a pre-existing
producer defect, not a regression caused by the formatted metadata flag.

The correction recognizes only explicitly declared, directly local, scalar,
writable CHARACTER units in a procedure scope. Numeric/* units, wrong-scope
names, host/use targets, constants, SAVE/initialized storage, pointers, VOLATILE
and INTENT(IN) targets are not exempted. No interpreter guard is weakened and
READ classification is unchanged. In 0.50, vendor patch 0108 restores completed
DO-body parent links using the normal producer factory invariant. The unchanged
valid loop fixture is consequently promoted to check/run success, exact `07\n`
output, and independent GNU execution. The original 0.49 source rejection is
preserved in the historical audit. No global-name fallback is added.

The shared purity classifier also admits this same local-file operation in the
existing SIMPLE path. J3/24-007, 15.7 C15108 and 15.8 distinguish external units
from local internal files and do not add a SIMPLE ban on the latter:
https://j3-fortran.org/doc/year/24/24-007.pdf
The two historical PURE/SIMPLE internal_io_unsupported fixtures are preserved
byte-for-byte and promoted in their manifest. The SIMPLE suite retains its
explicit GNU capability check and labeled PURE-reference limitation; a lowered
reference is not evidence of complete SIMPLE semantics.

Runner hardening requires the exact named diagnostic and recorded source path,
line and column in both --check and execution; rejected stdout must be exactly
empty. The former 0:0 unresolved-loop rejection is no longer an expected
negative after the metadata-only promotion. Host crash, trace and ICE markers
are rejected independently of the expected message. Success bytes and
GNU compile-only versus invalid-source distinctions remain unchanged. Run
`python3 tests/pure_internal_write/test_runner.py` for 14 adversarial self-tests.
