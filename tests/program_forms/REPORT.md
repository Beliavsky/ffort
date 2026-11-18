This historical suite report is retained for provenance. Current release results
are in `results.json` and `../../docs/VERIFICATION.md`.

# Program-form and PARAMETER verification

Recorded at 2026-11-14T04:32:42.469863+00:00 using GNU Fortran 14.2.0.

- Interpreter: **87/87 passed**, including both unchanged user programs (`32`, `55`).
- GNU Fortran: **84/84 applicable checks passed**, with 3 explicit checked-runtime safety skips.
- Harness: **25/25 self-tests passed**.
- Existing scalar-corpus regeneration: all 226 source hashes unchanged; the single
  optional-IMPLICIT-NONE manifest migration regenerates exactly.

The tested interpreter executable SHA-256 is
`a487c582f327ac5bf684ff1a08578728b54b6e23e925cce338d62c036195ffa9`.
This identifies the build used by this focused test run, not a distributed binary.
Later clean builds may have a different hash because of build paths/debug metadata.

The first updated build passed all parameter and exponent cases, but still rejected
headerless programs because FortFront represented their final END as a separate
AST node. That adapter issue was reported and fixed before the run recorded here.
A further legal-Fortran naming probe found that the pinned frontend cannot resolve
the identifier `parameter`. This release explicitly reserves and documents that
name, consistently with its existing reserved-name policy; all three identifier
positions have GNU compile-only boundary tests.

The original exponent implementation already passed the edge cases; the short
power program required headerless-main support rather than a power-operator fix.

Coverage, checking policy, reproducibility, and limitations are documented in
[README.md](README.md). Detailed stage results and original source are in
[final-results.json](final-results.json). This focused pass does not replace the
full native/scalar/array/CLI release verification.
