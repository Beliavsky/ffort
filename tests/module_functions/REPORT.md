This historical suite report is retained for provenance. Current release results
are in `results.json` and `../../docs/VERIFICATION.md`.

# Module-function verification report

The final clean-extraction aggregate run passed all 89 independently specified
interpreter cases. GNU Fortran passed all 76 designated baseline checks; 13
undefined-value or interpreter-policy cases are explicitly skipped. The harness
also passed all 10 of its own self-tests. See `results.json` for individual
commands, status, stdout/stderr and source hashes.

The 822 prior interpreter corpus cases passed unchanged. The full release
verification, native adapter/runtime/producer tests, source preservation and
platform caveats are recorded in `../../docs/VERIFICATION.md`.
