This historical suite report is retained for provenance. Current release results
are in `results.json` and `../../docs/VERIFICATION.md`. Since 0.10.0, the former
rank-two section-rejection fixture requires a runtime undefined-read error;
its source remains in the corpus under `rank_two_section_now_checked`.

# Rank-one array-section independent verification

Recorded UTC: 2026-11-14T11:36:38.768864+00:00

The clean-extraction `scripts/verify.py` execution produced `results.json` from the
current 183-case section corpus. Its source and manifest hashes were independently
rechecked against the files reported here.

| Category | Interpreter passed | GNU passed | GNU policy skips |
|---|---:|---:|---:|
| success | 120/120 | 118 | 2 |
| invalid | 25/25 | 25 | 0 |
| unsupported | 4/4 | 4 | 0 |
| runtime | 34/34 | 21 | 13 |

- Interpreter: **183 passed, 0 failed** in both execution and `--check` contract testing.
- GNU Fortran 14.2.0: **168 passed, 0 failed, 15 explicitly skipped**.
- Section-runner self-tests: **9 passed**, including generator reproducibility.
- 50 overlapping-assignment cases have deterministic independent Python-model outputs.
- GNU command flags: `-std=f2018 -pedantic-errors -fcheck=all -O0`.
- Manifest SHA-256: `fd0f6e8dd56e5dda8b2305842e4a7080c6a733aa2935044618afcff6a512b1a1`.
- Tested executable SHA-256: `b22c191cee956ef37747356b459911dcd757b505d342176f85c71f6f7bcba641`.

## Findings resolved before this result

1. Omitted triplet endpoints must retain lower/upper declared bounds even with a
   negative stride. `a(::-1)` is not Python-style reversal. The independent
   GNU differential run and WG5 reference caught the initial mistaken default;
   explicit reverse triplets and omitted-endpoint tests now agree.
2. Nested array-element references inside section bounds/stride initially failed
   the FortFront binding cross-check. The final adapter accepts and validates
   them; six independent cases cover same-array and other-array references,
   nested subscripts, target snapshots and loop-time bound changes.
3. The section harness verifies diagnostic text after removing source locations.
   A fixture filename containing `stride`, `bound` or `overflow` cannot falsely
   satisfy the expected diagnostic.

## Limits on the claim

The 15 GNU skips comprise 13 runtime safety/resource-policy cases and two
empty-expression evaluation-policy cases. They remain fully tested against the
interpreter's specified behavior; no GNU conformance comparison is claimed for
those cases. Constant section extents are checked at interpreter runtime, so
some invalid-shape sources are rejected earlier by GNU than by the interpreter.

This is a focused rank-one section regression result, not a claim of complete
Fortran conformance. Vector subscripts, array constructors and rank-two sections
remain outside the supported subset. Windows was not executed in this run.
