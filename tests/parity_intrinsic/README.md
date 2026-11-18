# PARITY intrinsic tests

Run `python3 tests/parity_intrinsic/run_tests.py --candidate PATH --gfortran gfortran`.
The 34-case manifest records independent expected values and separates GNU
execution, compile-only safety boundaries, and required compilation failures.
The GNU compiler uses Fortran2018, pedantic errors and runtime checks. Candidate
checking must remain silent, rejected/runtime-negative statements must not leak
output, and all subprocesses have a timeout.

`check_provenance.py` verifies the exact upstream demo_parity source before every
suite run. `provenance.json` records its pinned repository commit, source path,
byte count and hash. All other cases are synthetic. A passing original PARITY
demo is one new supported example, not support for the entire M_intrinsics corpus.

See `docs/PARITY.md` for limits and native mutation coverage.
