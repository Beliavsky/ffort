# Independent rank-two section oracle

The fixture generator computes expected output with Python lists and explicit
column-major indexing, independently of the interpreter. GNU Fortran checks
use `-std=f2018 -pedantic-errors -fcheck=all`; interpreter-specific alias and
evaluation policies are distinguished from GNU execution comparisons.

Run the full project verifier with `python3 scripts/verify.py`, or this suite with:

```
python3 tests/rank_two_sections/test_runner.py
python3 tests/rank_two_sections/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran --result results.json
```

Coverage includes both scalar/triplet orientations, two triplets, all omitted
operand forms, forward/reverse/runtime strides, negative and nonunit bounds,
zero extents, rank-reduced inquiries, dimension conformance, overlap snapshots,
INTEGER/REAL/LOGICAL operations, strided IN/OUT/INOUT dummies, rebasing, nested
forwarding, frozen addressing, definition flags and exact selected-address alias
checks. Nonmonotone and non-affine flattened selections have specific alias
regressions. Invalid forms and explicit unsupported boundaries remain negative
cases. Empty scalar expansion follows the existing evaluate-once policy.

The runner records commands, versions, fixture hashes and expected output, checks
candidate identity before/after execution and treats explicit GNU skips separately
from passes. `test_runner.py` guards token/format matching, diagnostic handling
and incorrect candidate statuses. See `docs/VERIFICATION.md` for final measured
counts and the release's clean-extraction evidence.
