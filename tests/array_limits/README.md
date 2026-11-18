# Array-cap resource policy tests

Run from the project root:

```sh
python tests/array_limits/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The runner reads `max_array_elements` in `src/fi_ir.f90`, generates 30 probes in a
temporary directory, and saves `results.json`. It is also part of
`scripts/verify.py`. The exact user example is preserved in
`examples/random_summary_100000.f90`; origin is recorded in the test result.

GNU Fortran independently compiles supported boundary sources and executes the
positive probes. Interpreter-only resource rejections have compile-only GNU
oracles. Extremely large/overflow-bound sources and the oversized source file
skip GNU because compiler representation limits are not the interpreter policy.
RNG summary values are range-checked independently, never compared with GNU's
sequence. The interpreter sequence is checked against a separate Python recurrence.

The cap is a resource policy, so boundary sizes intentionally derive from its
named constant rather than a second fixed numeric cap in the test code. Numeric
results and failure expectations are independently specified.

The optional Unix `profile_capacity.py` exercises 1e6/1e7 builds with bounded
child address spaces, native-GNU output comparisons, peak RSS and elapsed time.
It does not run the high-memory stress profile during ordinary verification.
See `docs/ARRAY-LIMITS.md` for exact invocation and measured configuration.
