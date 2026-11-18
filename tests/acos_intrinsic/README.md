# Real ACOS focused suite

Run `python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
The runner snapshots the candidate and checks stage-specific exits, diagnostics,
stdout and numeric values. Numeric parsing uses Decimal, not binary64; exact
cases preserve adjacent decimal distinctions and zero signs. Eighteen harness
self-tests run with `python3 test_runner.py`.

There are 28 synthetic source cases (17 GNU executions, four compile-only
boundaries and seven GNU rejections). The source files are not rewritten versions
of the user's example. Its exact original and minimally ACOS-enabled variant
are owned by the separate full-program mixture harness. The native tests
`test_acos_intrinsic.f90` and `test_acos_producer.f90` add 623 and eight checks.
The bounded contract and unrelated remaining dependencies are in docs/ACOS.md.

The runner also enforces one existing ACOS registry identity, unique intrinsic
names, and agreement between the declared registry size and literal entries.
