# Verification of prototype 0.10.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU reference commands use
`-std=f2018 -pedantic-errors -fcheck=all` (source corpora also use `-O0`).

## Clean extraction and full verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. Every aggregate check
passed. The final executable source, tests, fixtures and build files match that
checked extraction. Twelve combined result files and the aggregate log come
from this clean run. Verification documentation
and the file manifest were completed afterward; no executable source changed.

| Suite | Interpreter cases | Applicable GNU checks | Explicit GNU skips |
| --- | ---: | ---: | ---: |
| Independent | 226/226 | 206 | 20 |
| Arrays | 179/179 | 152 | 27 |
| Program forms | 87/87 | 84 | 3 |
| Whole arrays | 147/147 | 121 | 26 |
| Sections | 183/183 | 168 | 15 |
| Module functions | 89/89 | 76 | 13 |
| Numerical procedures | 88/88 | 85 | 3 |
| Argument association | 145/145 | 145 | 0 |
| Rank-two arrays | 136/136 | 136 | 0 |
| Rank-two sections | 269/269 | 262 | 7 |
| **Total** | **1,549/1,549** | **1,435** | **114** |

There are **zero failures**. GNU checks include compilation/rejection and, where
specified, execution against independent expected results. Runtime-policy and
valid-but-unsupported cases are deliberately not presented as GNU execution
proofs. Explicit skips are not compiler passes.

In addition:

- **108/108 generated nested-section programs** match independent Python list
  expectations and GNU execution, including lower bounds, empty arrays, strides,
  forwarding and copy-back.
- The arithmetic matrix produces **272 formatted REAL32/REAL64/mixed-kind values
  exactly matching GNU Fortran byte for byte**.
- All **17 native Fortran test programs**, **17 CLI/resource contracts** and
  **125 runner self-tests** pass. The new native adapter suite includes an
  accepted mixed/two-triplet baseline and **21 deliberate AST/IR disagreements**.
- `examples/matrix_sections.f90` passes final clean check/run and GNU comparison.
  The rectangular overlapping shift and reversed column actual produce
  `11 12 13 111 112 113 21 22 23 31 32 33`, followed by
  `12 112 22 32 3 2`.

The checked clean debug executable SHA-256 is
`45d42a85340c5e7b49b11278ef3393c5550bb6dc41f3062d15a81e809cfa3e86`.
This identifies the checked build, not a distributed binary; paths/debug metadata
can change the hash on another machine. The final ZIP is extracted and every
entry in MANIFEST.sha256 is verified after packaging. No compiler or build
artifacts are distributed.

## Added coverage and limits

The 269 new cases contain 222 interpreter successes, 27 checked runtime-policy
errors, 19 invalid programs and one explicitly unsupported vector-subscript
program. GNU executes 221 cases, performs 22 compile-only checks and rejects 19
invalid cases; seven explicit writable-overlap-policy cases are skipped. Source
fixtures have independently computed expected output and their runner verifies
that executable identity did not change during its run.

Coverage includes both scalar/triplet orientations, two-dimensional selections,
omitted operands, positive/negative/runtime strides, nonunit and negative bounds,
empty and singleton extents, rank-reduced dimension inquiries without data reads,
shape conformance, overlap-safe assignments, elemental numeric/logical operations,
REAL32/REAL64, strided IN/OUT/INOUT dummies, dummy rebasing, nested mixed-rank
forwarding, frozen addresses and per-element definition flags. Four regressions
exercise exact alias membership for nonmonotone and non-affine flattened
selections, avoiding both false overlap errors and missed intersections.

Rank-three and higher arrays, vector subscripts, dynamic declaration bounds,
array declaration initializers, array procedure results, explicit-shape/assumed-
size dummies, constructors, RESHAPE, reduction/transformational intrinsics and
unlisted features remain unsupported. See [RANK-TWO-SECTIONS.md](RANK-TWO-SECTIONS.md),
[RANK-TWO-ARRAYS.md](RANK-TWO-ARRAYS.md) and [ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md).
Functions retain IN-only dummies and scalar results. Storage/materialization
limits and the shared execution budget still apply. Scalar expansion evaluates
its scalar once even for an empty target; each section dimension is validated
independently. These are explicit deterministic safety policies.

## Reproducibility and provenance

Run `python3 scripts/verify.py` with Python 3, fpm and gfortran on PATH.
The verifier selects the debug executable using `fpm run --runner`, without a
shell or guessing an executable from timestamps. It handles paths with spaces.
The shell/PowerShell wrappers remain available. Windows execution is intended
but has not been verified on Windows; no upstream-wide test pass or full Fortran
conformance is claimed.

The clean aggregate log is under
`docs/verification/0.10.0/clean-room-full-verification.log`; each corpus retains
its combined `results.json`, expected outputs, commands and fixture hashes.
Earlier version reports and historical result files remain historical evidence,
not results for this release. Four formerly unsupported rank-two section
expectations were migrated to supported/checked behavior without dropping their
coverage.

All **469 vendored source/patch/metadata and top-level license/notice files**
compare byte-for-byte with the 0.9.0 archive. FortFront remains pinned to
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f` with the same seven documented local
patches. No new vendor patch or external dependency was introduced.
