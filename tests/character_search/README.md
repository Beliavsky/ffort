# Character-set search tests

From the repository root:

```sh
fpm test --profile debug --target test_character_search,test_character_search_producer
python3 tests/character_search/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The runner shares only execution/comparison helpers with `character_intrinsics`.
Its cases, manifest, independent 2,080-value matrix and source map are separate.
Both GNU and the candidate must match the fixed independent expected values;
invalid source and runtime-only safety cases are classified explicitly. Undefined
GNU variables are never executed as an oracle.

`source-map.json` verifies the original xutilities SHA-256 and two retained SCAN
expressions. These are standalone expression tests, not a retained `get_numbers`
body. No full-utilities or M_intrinsics example coverage is claimed.

See [the support contract](../../docs/CHARACTER-SEARCH.md).
