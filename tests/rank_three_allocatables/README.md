# Independent rank-three allocatable checks

Run from the repository root:

```sh
python tests/rank_three_allocatables/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran /absolute/path/to/gfortran
python -m unittest discover -s tests/rank_three_allocatables -p test_runner.py
fpm test --profile debug --target test_rank_three_allocatables
```

`manifest.json` contains fixed expected results, written independently of the candidate. GNU compilation/execution checks those results in isolated temporary directories with bounds checking. The candidate is separately checked and run; matching only exit codes is insufficient. Numeric token comparison accepts normal real rounding but not NaNs, missing values, extra output, or nonintegral values for integer expectations. Error cases require the correct check/run boundary and an error diagnostic. Runtime third-axis bounds failure must not leak the failed output record.

The 25 cases cover numeric and CHARACTER rank-three ALLOCATE/DEALLOCATE, allocation inquiries, nonunit third bounds, zero extents, assignment reallocation/preservation, allocatable function results, module lifetime, IN/OUT/INOUT descriptors, nested forwarding, OPTIONAL omission versus a present unallocated descriptor, and deferred CHARACTER lengths. Three capacity cases deliberately test interpreter limits and are not GNU language claims. Rank-four and LOGICAL allocatable rejection are also interpreter boundaries; GNU is deliberately skipped for those five policy cases.

The synthetic tensor augmentation exercises six branches (three dimensions, before/after). It is explicitly a synthetic driver, not an unchanged original function and not proof that `xutilities` compiles. No rank-three reduction is needed: checksums reduce rank-two planes. See `docs/RANK-THREE-ALLOCATABLES.md` for scope and remaining blockers.

`results.json` includes exact invocations, outputs, manifest/source fingerprints, candidate hash before and after the run, compiler version, and platform. A changing candidate fails verification. `gnu-results.json` is a separate GNU-only verification record. `native-results.txt` records the targeted native test result. The native test injects 19 corrupt descriptor/operand states and requires rejection independently at the adapter and runtime boundaries (38 checks).

The subsequent LOGICAL allocatable milestone promotes the unchanged logical
declaration/allocation boundary fixture to success. The current manifest has
21 GNU comparisons and 4 policy skips; original milestone evidence had 20 and 5.
