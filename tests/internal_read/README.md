# Internal numeric READ oracles

Run `python tests/internal_read/self_test.py`, then
`python tests/internal_read/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran`.
Both programs are explicit executables; no shell is used. GNU references compile
with `-std=f2018 -pedantic-errors -fcheck=all -O0` in fresh directories. Inputs
classified compile-only are never executed with GNU: they include undefined
values, interpreter resource/scope limits and the finite-result policy.

`manifest.json` classifies every case. `provenance.json` records the original
xutilities checksum, exact line ranges and CRLF hashes for both retained reader
bodies. The runner checks provenance before execution and checks that every
original-body wrapper contains those unchanged bytes. No old fixture is changed.
`results.json` records the exact candidate hash and observed stages.

There are 81 source cases, 20 harness self-tests, 224 native IR checks in
`test/test_internal_read.f90`, and 11 producer checks in
`test/test_internal_read_producer.f90`. This is not a full-release test claim.

See [the feature contract](../../docs/INTERNAL-READ.md), especially EOF/error
undefinedness and the original short-data message's undefined n. Expected STOP
stderr is an exact per-case allowance, not whitespace stripping or a general
suppression. Successful check stdout and stderr must be empty. Numeric output
uses exact Decimal equality, rejects nonfinite tokens, preserves signed zero and
adjacent INTEGER(8) values, and has no blanket floating tolerance.
