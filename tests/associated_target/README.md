# Independent ASSOCIATED identity tests

Run from the repository root:

```
python3 tests/associated_target/test_runner.py
python3 tests/associated_target/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran gfortran
python3 tests/associated_target/check_optional_target_omission.py --candidate /absolute/path/to/fortfront-interpreter --gfortran gfortran
```

The main runner checks CLI stages, output and diagnostics separately. GNU is only
an independent oracle, never an interpreter backend. Compilations use fresh
working directories and strict Fortran 2018 with runtime checks. The original
M_intrinsics demo and license hashes are verified before running cases.

Three whole nonpointer OPTIONAL TARGET omission cases deliberately have
specification expectations rather than GNU execution agreement. Their primary
references are in optional-target-standard.json. The separate receipt records
GNU's discrepancy; it never executes undefined/expired pointer cases with GNU.
Other compile-only cases document a narrower interpreter subset or safe rejection
of undefined programs. See ../../docs/ASSOCIATED-TARGET.md for the full contract.
