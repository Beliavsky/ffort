This historical suite report is retained for provenance. Current release results
are in `results.json` and `../../docs/VERIFICATION.md`.

# Independent whole-array verification

Recorded: 2026-11-14T11:10:12.245067+00:00

- Candidate: **147 passed, 0 failed**, with both check and execution stages tested.
- GNU Fortran 14.2.0: **121 passed, 0 failed, 26 explicitly skipped** policy cases.
- Harness self-tests: **3 passed**. The existing shared scalar and element-array
  harness self-tests run separately in the aggregate verifier.
- Categories: 89 successful programs, 25 invalid static programs, 6 deliberately
  unsupported programs and 27 checked runtime-failure programs.
- GNU successes include 87 output comparisons, 25 compile-time rejections,
  6 compiler-supported/interpreter-unsupported boundary probes and 3 checked
  bounds violations.
- GNU skips are 24 interpreter runtime-safety policies and 2 deterministic
  empty-array evaluation policies; no GNU conformance proof is claimed for them.

Independent expected outputs include 44 deterministic model-generated
self-overlap sequences: 20 INTEGER, 12 REAL and 12 LOGICAL. Snapshot-sensitive
checks retain scalar values and nested subscripts from the complete old array.
All values/conversions must succeed before assignment commits. Failed PRINT
records must emit no partial output while preserving earlier successful records.

The evidence is in `final-results.json` and `final-summary.txt`. JSON records
include commands, exit codes, stdout/stderr, GNU version, source/manifest hashes
and the candidate executable hash. Successful programs are compared by values,
not compiler-specific list-directed whitespace. The runner is portable Python;
this execution was Linux only, not Windows or full-language Fortran conformance.

Manifest SHA-256: `bc65f77abed84aa70eaa5fc26f980fb50ce08565c74ac860cc84b602369d9693`

Candidate SHA-256: `6bc5a9a0176ae3f77900c0947922d7b01539ae20a66d117caba338a21f00b7ff`
