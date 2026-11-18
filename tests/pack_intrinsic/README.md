# PACK regression suite

Run from the release root with a freshly built interpreter:

```sh
python3 tests/pack_intrinsic/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran
fpm test --profile debug --target test_pack_intrinsic
```

The CLI runner checks `--check` and execution independently, exact exit statuses,
diagnostics, no output leaks on rejected execution, and expected output. Each
GNU compilation uses a fresh temporary directory, strict Fortran 2018, runtime
bounds checks, and no optimization. `manifest.json` records the intended oracle
for every case. Runtime/compile-only/safety-only coverage is kept separate.

Coverage includes rank-one/two input, column-major order, nonunit lower bounds,
reversed sections, runtime shapes, scalar and array MASK, optional VECTOR tail
semantics, positional and reordered keywords, numeric kinds 4/8, LOGICAL and
fixed-length CHARACTER, zero-length CHARACTER, empty dimensions/results,
constructor and parameter composition, array function results, assumed-shape
actuals, repeated loops, user-defined PACK shadowing, impure elemental MASK
single evaluation, overlap-safe assignment, undefined values, underfilled
VECTOR, malformed arguments, budget exhaustion and aggregate temporary limits.

The zero-length CHARACTER GNU 14.2 execution crashed in libgfortran with SIGFPE.
It is compile-only here, with an independent expected interpreter result. GNU
also accepted mismatching CHARACTER lengths without diagnosis, so that
interpreter rejection is compile-only, not claimed as a GNU rejection.

The companion native test mutates valid numeric, CHARACTER and zero-result PACK
IR and checks the adapter and direct runtime paths independently. KIND is checked
without evaluating undefined source/mask data.
