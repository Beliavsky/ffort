# Independent LOGICAL allocatable verification

```sh
python tests/logical_allocatables/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran /absolute/path/to/gfortran
python -m unittest discover -s tests/logical_allocatables -p test_runner.py
fpm test --profile debug --target test_logical_allocatables
```

The manifest has fixed expected results independent of the interpreter. GNU compiles/runs in a fresh directory per case with standard conformance and bounds checking. Candidate `--check` and execution must independently meet the appropriate exit-code, diagnostic, and output contract. Undefined/unallocated storage and resource caps are interpreter safety policies, not deterministic GNU output oracles. Rank four remains a deliberate interpreter exclusion.

Before every suite run, `check_original_bodies` verifies the original full-file SHA-256 and three byte-exact body extracts in `cases/original_set_alloc_logical.f90`, including their line ranges and SHA-256. Original CRLF bytes inside those bodies are preserved. Only the surrounding program driver was written for the test. The original utility file is never modified. The driver exercises first allocation, replacement of already allocated INTENT(OUT) actuals, values at all ranks, and an empty tensor result.

Artifacts:

- `manifest.json`: fixed test cases and expected outputs.
- `extraction-evidence.json`: original source fingerprint and exact function-body provenance.
- `results.json`: candidate and GNU results, source/manifest/binary fingerprints, command lines, platform and compiler version.
- `gnu-results.json`: separate GNU-only verification.
- `native-results.txt`: focused native test build/run.
- `original-source-check.json`: unchanged full-source progress probe, not a claim of whole-module support.

The native test mutates descriptors and allocation operands directly, independently requiring frontend and runtime rejection. Rank-three reductions are not added or required; any aggregate logical checks use rank-two planes.
