# Independent exponent-model inquiry tests

```
python3 tests/exponent_inquiries/test_runner.py
python3 tests/exponent_inquiries/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran gfortran
```

The runner checks source hashes, compile/check/runtime stages, integer output and
error diagnostics separately. GNU uses strict Fortran 2018 and runtime checks in
fresh temporary directories. Compile-only cases are not execution agreements.
Original M_intrinsics sources and license are unmodified and hash-pinned.

The complete demo_minexponent executes; named parameter formats now advance
demo_maxexponent to its unchanged REAL128 literal boundary. See
../../docs/EXPONENT-MODEL-INQUIRIES.md for the exact whole-object contract,
unsupported subobjects and constant-expression limits.
