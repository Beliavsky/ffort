# OPTIONAL/PRESENT verification

Run from the package root:

```sh
fpm test --profile debug --target test_optional_arguments
python3 tests/optional_arguments/run_tests.py --candidate PATH_TO_INTERPRETER
```

The 31 fixtures contain 8 valid GNU differential programs, 15 compile-rejected
boundaries, 5 interpreter runtime-safety cases, and 3 GNU-valid runtime-policy
boundaries for absence forwarding into intrinsic optional slots. Runtime-case
GNU programs are compiled but never run by the suite. The exact-utility harness preserves seven original
routine fragments; the runner verifies normalized hashes and complete body text
before executing any test. Native tests add 25 independent adapter/runtime IR
mutation and baseline checks. The original `blocked_optional.f90` utility slice
also now runs, despite its historical filename.

Coverage includes INTEGER kinds 4/8, REAL kinds 4/8, LOGICAL, optional OUT and
INOUT, omitted leading/middle/trailing arguments, KIND type-only inquiries, reordered keywords, forwarding,
generics, bound methods, PRESENT on undefined actuals, ELEMENTAL array expansion,
empty arrays, missing required actuals, malformed PRESENT operands, and checked
absent reads/writes. OPTIONAL array/CHARACTER/derived-type dummies remain outside
the supported subset.

Absence forwarding is supported only between supported user-procedure OPTIONAL
dummies. SIZE DIM, SUM MASK, and SELECTED_REAL_KIND P policy fixtures prove the
current explicit absent-reference diagnostic rather than claiming GNU semantic
parity. Their manifest records GNU-valid expected results for reference. KIND
inquiries continue to inspect type without evaluating absent actual values.
