# B/O/Z INTEGER output verification

See `docs/BOZ-OUTPUT.md` for the bounded contract and primary standard clauses.
All 89 sources are synthetic focused tests; no original utility/demo is rewritten.
The Python oracle converts each value to its unsigned residue modulo its declared
32/64-bit width, then applies independently specified field/minimum-digit rules.
All records compare byte-exactly. The manifest prohibits numeric-line comparison.

Commands:

```
python3 tests/boz_formats/test_runner.py
python3 tests/boz_formats/run_tests.py --gfortran /path/to/gfortran
python3 tests/boz_formats/run_tests.py --gfortran /path/to/gfortran --candidate /path/to/interpreter
```

The final feature CLI SHA-256 is
`622e9b97d2d8629c6f9f6a6e51f8521e0288ea235b81c756d47e5f59e6906d74`.
It passes 89 outcomes: 70 GNU executions and 19 compile-only references. The
six INTEGER8 machine-minimum O/Z m=0 observations are not GNU execution agreement.
The first GNU failures and raw -O0/-O2 observations remain in `oracle-evidence/`.
The diagnostic first probe had GNU symmetric-range warnings and is not counted
as a final passing compile. Generated final fixtures compile with empty stderr.
Their machine-specific endpoints and standard symmetric-range counterparts are
separately labeled. All 83 initial source hashes remain unchanged.

Thirty-eight adversarial harness tests and 149 direct native assertions pass.
The native executable was linked with every official FPM compile_commands flag.
The feature used one `fpm build --profile debug` cache and one incremental rebuild
for the separate INTEGER output-kind guard; the first CLI was preserved too.
No FPM native aggregate or extra profile was built. Integration runs the full
clean aggregate. No vendor patch is needed; reserved 0100 remains unused.

Original demo_btest remained blocked in the standalone B/O/Z milestone. Slash
is outside that frozen feature; the integrated 0.49 slash profile now executes
the exact original with all 24 records byte-exact. See ../slash_formats/README.md
and the integer_bits --with-slash-formats capability profile.
