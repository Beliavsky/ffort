# INTEGER-kind independent checks

Run from any working directory:

```
python run_tests.py --candidate /absolute/path/to/interpreter --gfortran /absolute/path/to/gfortran --result results.json
python test_runner.py
```

Relative `--result` paths are resolved against this suite. `--candidate` and `--gfortran` can be used independently; `--only` filters case names by regular expression. The candidate is copied into a temporary immutable snapshot before execution.

The 23 cases distinguish static rejection (check/run status 1), runtime rejection (check 0/run 2), and success (both 0). The runner enforces diagnostics and output, with exact decimal token equality above 2^53, process timeouts, source/manifest/binary hashes and full compiler/process outputs in JSON. Twelve self-tests check false-positive rejection.

Eleven successful cases are compiled and executed with strict GNU flags. Undefined overflowing arithmetic, interpreter-only kind restrictions, and the explicitly supported two's-complement minimum conversion are skipped as GNU oracles with per-case explanations. SELECTED_INT_KIND(19) returns -1 here and 16 on GNU; the manifest records that supported-kind difference explicitly.

The additional public-IR test is `test/test_integer_kinds_runtime.f90`; the supported contract is documented in `docs/INTEGER-KINDS.md`.
