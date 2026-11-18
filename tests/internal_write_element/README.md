# CHARACTER array-element internal WRITE

See `docs/INTERNAL_WRITE_ELEMENT.md` for the bounded contract, observed results,
historical promotions and limits. The maintained corpus has 44 exact-source
fixtures. The original 35 and the initial seven followups remain byte-identical;
two separately named module-scoped variants test the supported form of the
retained main-TYPE grammar boundaries. No earlier failed observation is removed.

`check_original.py` verifies the exact fixture inventory, every fixture hash,
and the raw CRLF utility bodies. `test_runner.py` has 16 adversarial validator
tests. `run_tests.py` records candidate identity before/after, source hashes,
check/run stages and explicit GNU execution/compile-only/rejection modes.
Success requires exact stdout and empty diagnostics. Rejections require exact
path, location, complete message, newline, status and phase, not substrings.

The evidence archive is observational provenance. The normal maintained runner
does not load saved results to decide whether the current candidate passes.
