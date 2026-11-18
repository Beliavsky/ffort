# Verification of prototype 0.5.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0
(Debian 14.2.0-19), fpm 0.13.0 alpha and Python 3.12.14. GNU reference
commands use `-std=f2018 -pedantic-errors -fcheck=all -O0`.

## Clean extraction and full verification

The complete source release was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. Every check passed.
All implementation, test, corpus, manifest, example, verifier and vendored
source inputs were compared byte-for-byte with the checked extraction before
final packaging. Only evidence/documentation was updated after that run.

- Scalar corpus: **226/226 interpreter cases**, **206 GNU passes**, 20 skips.
- Element-array corpus: **179/179**, **152 GNU passes**, 27 skips.
- Program-form/parameter/power corpus: **87/87**, **84 GNU passes**, 3 skips.
- Whole-array corpus: **147/147**, **121 GNU passes**, 26 skips.
- New section corpus: **183/183**, **168 GNU passes**, 15 skips.
- Combined: **822/822 interpreter cases**, **731 applicable GNU passes**,
  **91 explicit skips**, and **zero failures**. Skips are not compiler passes.
- All **8 native Fortran test programs** pass, including 53 retained scalar/
  element runtime contracts, 34 whole-array contracts, 25 new section runtime
  contracts and the new section adapter baseline plus 28 deliberate mutations.
- **17/17 CLI/resource checks** and **65/65 harness self-tests** pass.

The checked clean debug executable SHA-256 is
`b22c191cee956ef37747356b459911dcd757b505d342176f85c71f6f7bcba641`.
This identifies the checked build, not a distributed binary. Build paths/debug
metadata can produce a different hash on another machine. Final ZIP extraction
and every entry in `MANIFEST.sha256` were checked again after packaging.

The unchanged requested examples still print **32** and **55**. The new
`examples/array_sections.f90` was run successfully from the clean extraction.

## Section behavior and independent coverage

Rank-one sections support lower/upper/stride triplets, omitted operands, dynamic
scalar INTEGER expressions, elemental operations, PRINT, scalar broadcasting
and conformable section/whole-array assignment. Descriptors are evaluated once
per statement and refreshed in loops. Bounds checks consider only selected
indices; an unused endpoint may be outside the array. Zero stride always fails.
Type/rank and known shape conflicts fail before execution; dynamic shape,
zero-stride and bounds checks occur at runtime. `--check` does not execute them.

Each assignment computes and converts a complete RHS temporary before writing,
so overlapping copies, reversals and bounds/strides that read the target use
its original data. Tests include 50 deterministic model-generated overlapping
assignment sequences, nested array elements in triplet operands, extreme
INTEGER endpoints/strides, per-element initialization, conversions, empty
sections, dynamic mismatches, PRINT atomicity and execution/resource limits.
Native tests verify exact descriptor budgets and forged-IR rejection as well.

Independent GNU checks corrected an important semantic detail: omitted triplet
endpoints remain the declared lower/upper bounds regardless of stride sign.
`a(::-1)` is not Python-style reversal; explicit reverse endpoints are required.
The adapter also handles FortFront's missing array-access metadata inside
triplet children narrowly while retaining exact declaration binding, type,
rank and subscript tree checks. See `FRONTEND.md` for the producer-side gap.

Empty array expressions evaluate no data elements, but still resolve/check
section descriptors and conformance. A scalar RHS is evaluated and converted
even for an empty target. These deterministic safety policies, undefined-data
checks and execution budgets are explicitly excluded from GNU comparisons
where appropriate. No full-language conformance or Windows execution is claimed.

## Preservation and provenance

All **639 existing source fixtures**, **459 vendored files** and both root
license/attribution files are byte-identical to release 0.4.0. No FortFront
source or patch changed. Four existing section rejection expectations migrate:
three now succeed; the uninitialized section read becomes a checked runtime
error and skips undefined GNU execution. Fixture names and sources are retained,
and the generators reproduce the changed expectations.

The ZIP is a complete self-contained source release with all pinned dependencies,
licenses, tests, examples and verification evidence. It excludes compilers,
binaries, build caches and Python bytecode. `MANIFEST.sha256` covers every
included file except itself. Historical versioned reports and historical
`final-results` files remain provenance; current results are the five
`tests/*/results.json` files and the clean-room log below.

## Evidence

- `verification/0.5.0/clean-room-full-verification.log`
- `verification/0.5.0/source-preservation.json`
- `../tests/sections/README.md` and `../tests/sections/REPORT.md`
- `../tests/sections/results.json` and the four retained suite results
