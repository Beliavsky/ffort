# Colon format regression suite

```
python3 tests/colon_formats/test_runner.py
python3 tests/colon_formats/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran
```

All 188 cases enforce one exact stage, diagnostic policy and output expectation.
The 176 positive GNU cases compare complete stdout byte-for-byte, including
spaces, empty records, separators and ordinary versus unlimited reversion.
Seven bounded-language or runtime-error fixtures are GNU compile-only, not
claimed as GNU execution agreement; five malformed formats require GNU compile
rejection. The runner snapshots and hashes the candidate and verifies every
source hash before and after execution.

The 34 harness checks include explicit trailing-separator/space, suppressed
literal, quoted colon, empty-record, record-boundary and output-atomicity attacks.
The native test_colon_formats adds 36 source/adapter/runtime/capacity assertions.
The complete original demo_digits lives in the model_character_intrinsics suite,
where `--with-colon-formats` selects its exact execution expectation.
See [the supported contract](../../docs/COLON-FORMATS.md).

Successful stderr and --check stdout must be exactly empty, not merely whitespace.
An explicit empty expected stdout rejects all whitespace leaks, including negative
cases. Expected formatted spaces and record terminators remain byte-exact. GNU
successful runtime execution must also have empty stderr. Compiler warnings
remain recorded: GNU warns that the valid FORALL fixtures are obsolescent.
