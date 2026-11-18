# Model/character intrinsic regression suite

Run in the combined release, with the final CLI and GNU compiler paths:

```
python3 tests/model_character_intrinsics/test_runner.py
python3 tests/model_character_intrinsics/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran --with-colon-formats
```

Omit `--with-colon-formats` only for the isolated three-intrinsic patch. That
profile requires the unchanged original demo_digits to reject its colon format;
the combined profile requires it to execute. Both profiles contain 120 cases.
Results record the active profile, fixture and binary hashes, exact stages,
stdout/stderr, and GNU compilation/execution separately. `results.json` preserves
the frozen intrinsic-only evidence; `combined-results.json` records the separate
colon-enabled validation. The release verifier should use the combined profile.

The two complete upstream sources and their MIT license are byte-preserved.
`upstream.json` identifies their repository, commit, original paths and hashes.
No dynamic expected-result fallback is allowed. There is no numerical tolerance
in this suite. Original formatted records and explicit newline examples are
checked exactly; ordinary list-directed numeric output uses exact Decimal tokens.

Five native programs provide 5,007 structural/numerical assertions and 14
producer cases: test_digits_intrinsic, test_newline_intrinsic,
test_rrspacing_intrinsic, test_rrspacing_bit_oracle and
test_model_character_producer. The independent bit oracle covers 340 finite
IEEE patterns, including both input signs and positive-zero results. The 28
harness checks reject crashes, missing diagnostics, incorrect stages, output
leaks, registry duplicates, decimal coalescence, signed-zero loss and tolerances
that might mask tiny values. See [the contract](../../docs/MODEL-CHARACTER-INTRINSICS.md).

Successful stderr and --check stdout must be exactly empty, not merely whitespace.
An explicit empty expected stdout rejects all whitespace leaks, including negative
cases. Expected formatted spaces and record terminators remain byte-exact. GNU
successful runtime execution must also have empty stderr. Compiler warnings
remain recorded: GNU warns that the valid FORALL fixtures are obsolescent.
