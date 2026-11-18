# Counted-loop and IF-chain regressions

See [the contract](../../docs/CONTROL-FLOW.md). Run `run_tests.py --candidate PATH`
with GNU Fortran on PATH, or pass `--gfortran PATH`. Each source file is checked
and executed independently. Successful ordinary programs are also compiled with
`-std=f2018 -pedantic-errors -fcheck=all` and compared to GNU output. The two
full-int64 mathematical-loop cases have explicit policy outputs because signed
trip-count overflow is not a reliable compiler oracle. Source rejects must emit
no output even when a PRINT precedes the rejected statement. Runtime errors
must exit with status 2. JSON evidence is written to `results.json`.
