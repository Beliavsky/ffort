# Fixed and assumed CHARACTER length inquiry regression

Separate followup to descriptor-length constructor support; the frozen 72-case suite is unchanged. Twenty source cases pass the corrected feature CLI SHA256 `aa46c738c4793748e9c3959c2586679bca99d3a1fd9a8549cd16fbab9a92db2c`.

Ten cases have GNU execution agreement, four retain independently expected zero-trip descriptor length with GNU compile-only evidence, and six genuinely deferred unallocated cases are compile-only GNU references with exact pinned candidate runtime failures. GNU 14 reports zero for the four runtime-length zero-trip inquiries; these initial outputs are retained in `gnu-first-results.json`, not adopted as the correct expected length. Fixed or assumed length parameters exist independently of allocation, unlike genuinely deferred `CHARACTER(:)` parameters. The zero-trip constructor rule is interpreted with J3/18-007r1 section 7.8; <https://j3-fortran.org/doc/year/18/18-007r1.pdf>.

Two original historical cases are copied byte-for-byte from `tests/scalar_allocatable_character/cases`: `runtime_local_fixed_length.f90` and `fixed_optional_unallocated.f90`. Their hashes and relative origins are in `provenance.json`. No originals were edited. Synthetic cases cover scalar/rank-one runtime local declarations, present unallocated assumed-length allocatable dummies, direct LEN, constructor LEN and zero-trip constructor LEN. All success output is byte-exact. The two original cases are quiet success. Six deferred-unallocated negative diagnostics were pinned only after observing correct runtime stages; initial metadata and first receipts are retained locally.

```
python3 run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran --result results.json
python3 self_test.py
python3 check_generator.py
```

Successful stderr and CHECK stdout must be empty; negative runtime output must be exactly empty and diagnostics exactly match path/location/text. Candidate identity and every source hash are checked before/after execution. Thirty comparator adversarial checks and nineteen generated-file replay checks pass (18 generated sources plus manifest; two originals are separate immutable inputs). No build or native linking is performed by this suite.
