# Runtime format verification

From the repository root, with GNU Fortran on PATH:

```
python3 tests/runtime_formats/check_provenance.py
python3 tests/runtime_formats/test_runner.py
python3 tests/runtime_formats/run_tests.py --candidate /absolute/path/to/interpreter
python3 tests/runtime_formats/run_original.py --candidate /absolute/path/to/interpreter
fpm test --profile debug --flag '-ffree-line-length-none' --target test_runtime_formats
```

The source runner requires silent successful --check and exact output bytes,
including significant spaces and absence of a final newline. No numeric, case or
whitespace normalization is permitted. Error fixtures preserve exact committed
prefixes and use compile-only GNU checks. Original closure/body/full-source hashes
and the MIT license are checked before both runners. See
[the contract](../../docs/RUNTIME-FORMATS.md) for limits and provenance scope.

The native program independently tests producer format metadata and rejects
source-binding and runtime descriptor mutations. Its fixed-length internal WRITE
baseline emits no stdout; malformed controls never commit a record.
