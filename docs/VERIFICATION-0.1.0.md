# Verification of the delivered prototype

Recorded 14 November 2026 on Linux x86-64, GNU Fortran 14.2.0 (Debian 14.2.0-19), fpm 0.13.0 alpha, Python 3. Interpreter source is compiled with fpm's debug profile. The independent GNU oracle uses `-std=f2018 -pedantic-errors -fcheck=all -O0`.

## Completed checks

- `fpm build --profile debug`: passed.
- `fpm test --profile debug`: passed. Two Fortran test programs cover 32 runtime contracts, 8 frontend metadata compilations (7 sequential mixed-mode calls plus one explicit-character-kind call), and 4 AST/IR admission contracts.
- Clean-room rebuild: passed from a new directory containing only deliverable source, tests and the vendored dependency, with no pre-existing build cache or binaries. The same native tests passed. No network dependency fetch was required.
- CLI/resource checks: 17/17 passed, including input/file/option errors, source size/line/name/symbol/nesting/argument limits and work-budget exhaustion.
- Independent runner self-tests: 18/18 passed.
- Independent source corpus: **226/226 interpreter checks passed**. GNU Fortran passed **206/206 applicable checks**; 20 stronger interpreter safety checks were explicitly skipped by the GNU oracle. Categories: 139 valid execution cases, 22 syntax negatives, 28 semantic negatives, 17 unsupported boundaries, 18 runtime safety cases and 2 static safety cases. See `tests/independent/REPORT.md` and `final-results.json` for the executable hash, per-case source hashes, commands, outputs and decisions.
- Included examples: `sum_squares.f90` produced sum 385 and final loop variable 11; `scalars.f90` produced ratio 1.75, truncated value 1 and intrinsic results 8, 1, 3, 1. Malformed and runtime-error examples are intentionally rejected at their respective stages.

The independent source corpus includes 100 reproducibly generated bounded numeric expressions, using seed 20261114. Positive expectations were authored independently and checked against GNU Fortran. Integer outputs are compared exactly; real outputs allow real32 printing roundoff. Whitespace is normalized, except explicit blank-line assertions. Runtime and extra static safety checks are explicitly separate from standard-language compiler rejection claims.

## Defects exposed and addressed

- FortFront's fresh/sequential default-real mode metadata leak: fixed locally before semantic annotation, with mixed-mode API regressions.
- CHARACTER length reported as kind: fixed locally with separate explicit-kind regression. CHARACTER variables remain unsupported by the interpreter.
- Malformed `x=(1+)` silently accepted upstream: rejected by strict source recognition; the adapter also rejects the incomplete AST. The general upstream parser is not claimed fixed.
- Incomplete nested-DO parent/scope links: adapter falls back only to the validated sole PROGRAM scope and requires the exact declaration identity.
- Invalid constant declaration initializers: evaluated with the checked pure scalar evaluator at compile time and rejected by `--check`, rather than failing only when execution starts.
- Empty PRINT and adjacent character fields: explicitly covered by source regressions.
- A final independent code review found consecutive `.not.` without parentheses and PROGRAM-name collisions accepted by both initial parsers. The source guard now rejects these; parenthesized double negation remains accepted. Dedicated positive/negative regressions cover the correction.

## Important limits of the evidence

This is a bounded prototype test suite, not whole-language conformance, an exhaustive fuzz campaign, a sandbox audit, or a claim of production readiness. The code review used 20 additional targeted differential/stress probes and did not establish security against hostile input. The complete upstream FortFront test suite was not run as part of this prototype delivery. Two upstream sources are patched; their exact diff and retained MIT license are included. The original evaluation checkout is unchanged.

No generated executable, compiler, `.mod`, object file, or build cache is distributed. Build logs are retained under `docs/verification`; they are evidence for the recorded platform, not portable build artifacts.
