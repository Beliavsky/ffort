# ERFC_SCALED contracts and accuracy

See [the supported contract](../../docs/ERFC-SCALED.md).

`run_tests.py` executes ordinary GNU/candidate contracts, explicit runtime safety
checks and static boundaries. It verifies every fixture hash and the complete
unchanged upstream example/license. `test_runner.py` checks exact text/integer
comparison, finite numeric comparisons and clean check gating.

`run_accuracy.py` separately checks 439 inputs against independent 120-digit
mathematical references with 2 ULP / 4 ULP budgets. It records GNU's runtime endpoint
Infinity/zero discrepancies instead of labeling them execution agreement.
`test_accuracy.py` ensures zero cannot pass as a small positive subnormal,
nonfinite values fail, and output order/count remain checked. The reference
file includes exact binary inputs, explicit methods and both negative overflow
neighbor proofs. Reproduction uses only Python standard-library modules; optional
reference regeneration uses mpmath 1.3.0 and the fixed-seed generator.

No historical source fixture is changed. GNU is a reference compiler only,
never an execution backend for the interpreter.
