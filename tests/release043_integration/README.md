# Release 0.43 independent composition acceptance

These twelve programs were independently written for this release. Every case is
synthetic, not an unchanged upstream demo, extracted utility body, or replacement
implementation. Original utility/demo preservation and full original-program
acceptance belong to the dedicated feature suites. No original fixture is edited.
The full xutilities source still exceeds the unchanged default 1,000,000-element
cap with its 100-million-element declaration; this suite does not claim it runs.

Coverage crosses scalar CHARACTER allocation/reallocation, owned function results,
IN/OUT dummy transfer, defined CHARACTER +, named OPTIONAL generic omission and
keyword use, internal numeric READ, PURE calls, null/slash input, IOSTAT, DIGITS,
RRSPACING, NEW_LINE, colon termination, significant spaces, input-error/EOF
undefinedness, and atomic failed output. Four cases are GNU compile-only because
undefined-value execution or FortFront's single-record policy is not a GNU oracle.
Eight cases use strict GNU execution and exact independently specified bytes.
No floating-point tolerance or normalized CHARACTER whitespace is permitted.
Successful checks and runs must have genuinely empty stderr; --check is silent.

Run from any working directory:

```
python3 tests/release043_integration/test_runner.py
python3 tests/release043_integration/run_tests.py --candidate /absolute/fortfront-interpreter --gfortran /absolute/gfortran
```

The runner snapshots and hashes the executable, pins manifest and source hashes,
checks them again afterward, uses fresh compiler directories and strict F2018 GNU
flags, and writes results.json. GNU-only or candidate-only runs are supported but
are explicitly counted as partial validation. The 38 harness self-tests defend
exact bytes, Decimal precision/sign of zero, silent diagnostics, atomic output,
exit codes, source integrity, and executable snapshot integrity.

The native test `test/test_release043_composition.f90` independently exercises
repeated immutable execution, allocation ownership after malformed copies,
duplicate READ targets, and exact source identity for same-valued allocatable
internal files. It must run against the merged library, not an owner's build.

Provenance: synthetic fixture author is the independent release043 composition
worker. The strict runner/self-test infrastructure is adapted from certified
0.42 release042_integration; no 0.42 sources or fixtures are changed. The manifest
is pinned in the runner; any intentional fixture change requires a new pin and
rerun. Existing feature-native malformed IR tests remain independently required.
