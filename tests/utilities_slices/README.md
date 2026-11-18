# Smaller utilities programs

The original `source/xutilities.f90` is retained byte for byte. `source_parts/`
contains an exact reconstruction map, 549 top-level routine fragments (retaining two internal procedures) and eight driver
statement blocks. Those reference fragments still have module dependencies;
they are not 549 standalone programs.

From the package root, the following self-contained programs run:

```sh
fpm run fortfront-interpreter -- tests/utilities_slices/logical_runs.f90
fpm run fortfront-interpreter -- tests/utilities_slices/elemental_factorial.f90
fpm run fortfront-interpreter -- tests/utilities_slices/generic_if_else.f90
fpm run fortfront-interpreter -- tests/utilities_slices/activation_functions.f90
fpm run fortfront-interpreter -- tests/utilities_slices/bounded_values.f90
```

Their 15 procedure bodies are extracted from the input without algorithm changes.
The harnesses normalize CRLF to LF, reduce module exports, declare required
constants locally one per declaration, and supply focused main programs.
`manifest.json` records the source line ranges and normalized body hashes.

Some historical `blocked_*` harnesses now execute with OPTIONAL, logical intrinsics and control-flow support. Others still isolate explicitly unsupported features. Their expected rejection
is a passing boundary test, not successful execution of that utility. The runner
requires the specific diagnostic and no program output. `results.json` records
GNU Fortran and interpreter outcomes. One kind-inquiry case deliberately tests
the supported REAL32/REAL64 model rather than GNU's wider storage kinds.

```sh
python3 tests/utilities_slices/split_source.py --check
python3 tests/utilities_slices/run_tests.py --candidate PATH_TO_INTERPRETER
python3 tests/utilities_slices/check_full_source.py --candidate PATH_TO_INTERPRETER
python3 tests/utilities_slices/run_kind_matrix.py --candidate PATH_TO_INTERPRETER
```

The matrix checks 5,488 calls spanning optional argument combinations, keyword
permutations, mixed positional prefixes, and INTEGER(8) extremes against a small
independent mathematical model. It is not a full-language conformance suite.
See [the feature and boundary guide](../../docs/UTILITIES.md).
