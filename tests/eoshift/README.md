# EOSHIFT verification

From the repository root:

    python3 tests/eoshift/test_runner.py
    python3 tests/eoshift/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran

The suite contains 141 fixed outcomes: 103 strict GNU executions, 20 matching
source rejections and 18 compile-only bounded cases. All numeric comparisons are
exact, including signed zero. Formatted CHARACTER cases and the full original
demo use byte-exact output. Successful stderr and check stdout must be empty.

The unchanged original and its MIT license are hash-verified before execution.
Independent Python position arithmetic generates ordinary vector/matrix
expectations; the original's complete expected output comes from its retained
strict GNU run. The runner never delegates candidate execution to GNU.

Native targets are test_eoshift (5415 assertions) and test_eoshift_producer
(10 producer checks). The runner has 33 adversarial self-tests. Detailed scope,
subset exclusions, resource limits and GNU machine-boundary caveat are in
[EOSHIFT](../../docs/EOSHIFT.md). GNU's crash on the non-symmetric machine-minimum
SHIFT is separate evidence, never a successful execution oracle.
