# ISNAN GNU-extension contracts

See [the bounded contract](../../docs/ISNAN.md). The fixture manifest explicitly
labels the GNU extension and compiler stages; the oracle uses `-fall-intrinsics`.
A strict F2018 build without that flag is separately required to reject ISNAN.

Run from the repository root:

    python3 tests/isnan_intrinsic/test_runner.py
    python3 tests/isnan_intrinsic/check_provenance.py
    python3 tests/isnan_intrinsic/run_tests.py --candidate /absolute/path/to/fortfront-interpreter

Eight `original_sort_*.f90` wrappers preserve the complete original CRLF quick_sort
body and both nested procedures. Only module/DP/driver scaffolding is synthetic;
there is no ISNAN stand-in. Provenance and every fixture hash are verified before
execution. No old fixture is rewritten or relabeled as helper-free evidence.

The accepted domain contains finite REAL4/8 values only. NaN/Infinity generation
and forged nonfinite input remain explicit safety rejections. The tests do not
claim to execute quick_sort's early return for NaN input. Native tests cover both
metadata and nonfinite policy separately from GNU source execution.
