This historical suite report is retained for provenance. Current release results
are in `results.json` and `../../docs/VERIFICATION.md`.

# Array extension independent verification

The final candidate passed all **179/179** array checks. GNU Fortran 14.2.0 passed
all **156/156** applicable reference checks; 23 are explicitly skipped under the
oracle policy documented in README.md. The same candidate also passed the complete
unchanged original corpus: **226/226**, with GNU passing **206/206** applicable
reference checks and 20 documented safety skips.

Combined independent source coverage is **405/405 interpreter cases** and
**362/362 applicable GNU checks**, with 43 explicit compiler-oracle skips.
The 17 CLI/resource-boundary checks, original 18 runner self-tests, and new 10
array-runner self-tests all passed. A clean-source build made with the final source was used for
both final source-corpus runs; its SHA-256 is recorded in each JSON report.

The initial test run found a genuine FortFront mixed-case array binding problem:
`Values`, `vALues` and `VALUES` were not resolved as the same array. That caused
valid subscripts to be treated as user procedure calls. The producer-side scope
canonicalization fix was verified by rerunning the explicit mixed-case case and
all array and original scalar cases, rather than suppressing the regression.

Array coverage includes declaration shapes, type behavior, expressions, storage
independence, loops, exact storage limits and compile/runtime rejection boundaries.
Every runtime case passes `--check` and fails at execution with the appropriate
checked status. Static failures produce no program output. Two PRINT atomicity
cases require earlier output to remain but forbid any partial failing record.

See final-results.json and final-summary.txt for the array evidence, and
scalar-regression-final-results.json and scalar-regression-final-summary.txt for
the original-suite rerun against this exact candidate. Development-only reports
were moved out of the deliverable tree. This evidence does not claim exhaustive
language conformance, a hostile-input audit or Windows execution validation.
