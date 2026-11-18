# Verification of prototype 0.4.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0 (Debian
14.2.0-19), fpm 0.13.0 alpha and Python 3.12.14. Debug-profile builds and GNU
reference checks use the same pinned sources as the delivered archive. GNU
reference commands include `-std=f2018 -pedantic-errors -fcheck=all -O0`.

## Clean extraction and full verification

The complete source release was archived, extracted into a fresh directory
without any build cache, and rebuilt with `python3 scripts/verify.py`. All checks
passed. Final implementation, test, manifest, verifier and vendored sources were
compared byte for byte with that checked extraction before packaging. No network
dependency download was needed. Evidence/docs were added after verification;
no executable or test source changed.

- Original scalar corpus: **226/226 interpreter cases**, **206 applicable GNU
  passes**, 20 explicit skips.
- Existing element-array corpus: **179/179 interpreter cases**, **153 applicable
  GNU passes**, 26 explicit skips.
- Program-form/parameter/power corpus: **87/87 interpreter cases**, **84 applicable
  GNU passes**, 3 explicit skips.
- New whole-array corpus: **147/147 interpreter cases**, **121 applicable GNU
  passes**, 26 explicit skips.
- Combined: **639/639 interpreter cases**, **564 applicable GNU passes**, 75
  explicit skips and **zero failures**. Skips are not compiler passes.
- All **6 native Fortran test programs** pass: 53 retained direct runtime
  contracts, 34 new whole-array runtime contracts, original frontend metadata
  and AST checks, existing array/program-form adapter checks, and a new valid
  whole-array baseline plus 20 independent shape/context disagreements.
- **17/17 CLI/resource checks** and **56/56 harness self-tests** pass.

The clean debug executable SHA-256 is
`e365f07baafce0e46ffeb1d8201b148af721fff8fda44aab998823d2d3fb9130`.
This identifies the checked build, not a distributed binary. Different build
paths/debug metadata can produce a different hash on another machine.

## New behavior and checked boundaries

Rank-one INTEGER, REAL and LOGICAL arrays support scalar broadcast, conformable
array expressions, whole-array PRINT and the existing six elemental intrinsics.
Extent determines conformance, independently of declared lower bounds. Scalar
contexts reject array values before execution. Assignment computes a complete
temporary before committing, so self-references and nested subscripts see the
old target throughout. PRINT evaluates an entire expanded record before output.
The limit is 64 source items and 65,536 expanded values per PRINT.

Tests cover numeric conversions, all supported operators, zero extents,
non-unit/negative bounds, mixed case, powers, IF/DO integration, budgets,
initialization, bounds failures, overflow, invalid arithmetic and unsupported
sections/constructors. There are 44 independent model-generated snapshot-sensitive
sequences across INTEGER, REAL and LOGICAL arrays. Native IR tests additionally
check exact work budgets and malformed metadata. The adapter derives rank and
extent independently and rejects forged caches, cycles and invalid contexts.

Scalar broadcast evaluates its RHS once, even for an empty target. An empty
array-valued expression evaluates no elements, including scalar subexpressions.
The corresponding safety-policy cases are explicitly excluded from compiler
conformance claims. See `ARRAYS.md` and `../tests/whole_arrays/README.md`.

The unchanged requested example programs still print **32** and **55**.
`examples/whole_arrays.f90` and `examples/whole_arrays_empty.f90` demonstrate the
new feature without requiring new syntax outside the documented subset.

## Preservation and provenance

All **492 existing source fixtures** (226 scalar, 179 element-array, 87
program-form) are byte-identical to release 0.3.0. Eight previous rejection
expectations migrate because their sources are now supported. Five become
successful execution checks; three intentionally uninitialized whole-array reads
become checked runtime-error cases. The latter now skip GNU execution rather
than claiming a portable uninitialized-read oracle. Their names are retained
for provenance. The corpus generators and manifests include the migrations.

All **459 vendored files**, including patches, and both license/attribution files
are byte-identical to 0.3.0. No additional FortFront patch was needed. Historical
reports remain clearly versioned; they are not the verification for this release.
The final `MANIFEST.sha256` covers every distributed file except itself. The ZIP
contains complete source and evidence, without a compiler, binaries or build cache.

## Reproduction and evidence

Run `fpm build`, `fpm test`, and `python3 scripts/verify.py`. The last command
runs all native tests, CLI and harness checks, and all four source corpora.
The Python verifier and PowerShell wrapper remain portable source workflows;
**Windows has not been executed or verified**.

- `verification/0.4.0/clean-room-full-verification.log`: fresh build and every
  aggregate verification stage.
- `../tests/*/results.json`: current clean-run stage outcomes, commands and hashes.
- `../tests/whole_arrays/REPORT.md` and `final-results.json`: independently recorded
  focused verification against the development build, identified by its own hash.
- `VERIFICATION-0.3.0.md` and older reports: historical evidence.

Passing selected tests is not a full-language conformance estimate, upstream-wide
suite pass, production-readiness claim or security audit. Sections, constructors,
multidimensional arrays, array parameters and inquiry/reduction intrinsics remain
unsupported, along with the other boundaries in README.md.
