# Independent array-intrinsic verification

`generate_cases.py` produces deterministic Fortran sources and expectations without
importing interpreter implementation code. Python computes the reduction and
matrix results independently. The runner additionally compiles and executes valid
numeric examples with GNU Fortran, using an isolated temporary directory per case.

Run from the package root:

```sh
python3 tests/array_intrinsics_independent/generate_cases.py
python3 tests/array_intrinsics_independent/test_runner.py
python3 tests/array_intrinsics_independent/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The 234 cases cover:

- SUM, PRODUCT, MINVAL and MAXVAL on INTEGER, REAL(4) and REAL(8), whole arrays,
  rank-one and rank-two sections, scalar and conformable array masks, runtime DIM,
  nested reductions, expressions, dummy arrays and non-unit lower bounds.
- Empty selected sets, empty reduction axes and empty retained axes, extreme
  INTEGER values, kind-sensitive real accumulation and skipped masked-out reads.
- Numeric and logical DOT_PRODUCT and all three permitted MATMUL rank forms,
  mixed types/kinds, reversed sections, zero extents, 24 deterministic randomized
  matrix products and 24 randomized masked section cases.
- Shape-only inquiry behavior, reevaluated DIM in a loop, uninitialized reads,
  arithmetic overflow, invalid strides/bounds, dynamic conformance failures,
  atomic PRINT, work limits and bounded result sizes.
- Invalid type/rank/argument combinations and intentionally unsupported keywords.

For safety-policy cases GNU Fortran is used for compilation only: undefined
uninitialized reads and overflow are not executed or treated as compiler oracles.
Each manifest entry explicitly identifies its GNU baseline mode. Literal invalid
DIM values are rejected by GNU at compilation, whereas the interpreter checks DIM
at execution, just as it does its existing array inquiries. Both outcomes are
checked separately. The integer MAXVAL empty identity is -2147483648, the most
negative supported INTEGER, matching the tested GNU Fortran 14.2.0 runtime.

`results.json` records tools, flags, exits, stdout, stderr, diagnostics, source
hashes, manifest hash and candidate executable hash. The runner checks both
`--check` and execution, forbids output from rejected sources and nonempty
successful diagnostics, uses exact integer/logical comparison and explicit real
tolerances, and fails on timeouts or launch failures. `test_runner.py` checks the
runner's fail-closed behavior and generator reproducibility. Platform-specific
list-directed whitespace is not compared.
