# Release 0.44 independent composition verification

The independent suite at `tests/release044_integration` crosses the four feature
lanes with existing procedure, allocation, formatting, output staging and metadata
rules. It contains 16 exact GNU execution comparisons, nine runtime failures and
four source rejections. GNU independently compiles all accepted oracle sources:
16 run, 11 are explicitly compile-only and two invalid programs must be rejected.

Source preservation is enforced with a pinned synthetic manifest and per-file
SHA256. No original xutilities or M_intrinsics file is copied into or altered by
this suite. Those originals remain independently required in the feature suites.
The existing whole-library 1,000,000-array-element limit is not raised.

The formatted/CHARACTER oracle is byte-exact. List-directed numbers use exact
Decimal values, explicit sign-of-zero checks and no nonfinite values. Silent
success is required; --check cannot leak output. Failures have exact statuses,
case-specific diagnostics and exact completed stdout, including pending-record
prefixes without fabricated newlines. Resource policy cases are not represented
as GNU runtime agreement.

The 34-check native program combines all four feature families, mutates copies
through independent parser/adapter/runtime gates, verifies exact binding identity,
and repeats the pristine program after failures. Its manual link hook consumes
an existing merged library and records integrity hashes; it does not build one.
The 44 Python harness tests independently challenge the oracle and provenance.

Run `tests/release044_integration/verify.sh CANDIDATE GNU` and the usual native
suite. A focused preview pass is not a full release certification. Final release
validation must use the final clean archive, aggregate verifier and all original
feature suites; record its immutable candidate hash separately from previews.
