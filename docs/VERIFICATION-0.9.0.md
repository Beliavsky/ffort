# Verification of prototype 0.9.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU reference commands use
`-std=f2018 -pedantic-errors -fcheck=all` (source corpora also use `-O0`).

## Clean extraction and full verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. Every aggregate check
passed. All **1,917 non-result files** were compared byte-for-byte with that
checked extraction before final packaging. Ten result evidence files were
copied from the clean run; only this verification report and the regenerated
file manifest were updated afterward.

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
| **Total** | **1,280/1,280** | **1,173** | **107** |

There are **zero failures**. GNU checks include compilation/rejection and, where
specified, execution against independent expected results. Runtime-policy and
valid-but-unsupported cases are deliberately not presented as GNU execution
proofs. Explicit skips are not compiler passes.

In addition:

- **108/108 generated nested-section programs** still match independent Python
  list expectations and GNU execution, including lower bounds, empty arrays,
  strides, forwarding and copy-back.
- The existing arithmetic matrix still produces **272 formatted REAL32/REAL64/
  mixed-kind values exactly matching GNU Fortran byte for byte**.
- All **16 native Fortran test programs**, **17 CLI/resource contracts** and
  **111 runner self-tests** pass. The new native adapter suite includes accepted
  explicit, assumed-shape and local array baselines, nested loops, a zero-total
  0-by-100000 shape, and **21 deliberate AST/IR disagreements**.
- `examples/matrix_multiply.f90` passes check/run and GNU comparison. Its result
  is `76 100 103 136` in column-major order, followed by counts `4 2 2`.

The checked clean debug executable SHA-256 is
`bc129af28873541befefdaf0396dc6128cd30673660839f63067b093a1a9ed86`.
This identifies the checked build, not a distributed binary; paths/debug metadata
can change the hash on another machine. The final ZIP was extracted and every
entry in MANIFEST.sha256 was verified after packaging.

## Added coverage and limits

The 136 new cases contain 71 interpreter successes, 37 checked runtime-policy
errors, 16 invalid programs rejected by both implementations, and 12 standard-
valid but unsupported programs rejected by this interpreter. Of the success
cases, 69 execute under GNU against independent expected values; two exercise
interpreter evaluation/alias policies and use GNU compilation only. The new
suite has no GNU skips. Its runner rejects changed executable hashes during a
run and records versions, commands, fixture hashes and expected results.

Coverage includes first-index-fastest ordering, two independent scalar bounds
checks, negative/nonunit lower bounds, empty and singleton shapes, same-total
but unequal dimension extents, whole-array snapshots, elemental numeric/logical
operations, REAL32/REAL64, dimension inquiries without data reads, rank-two
IN/OUT/INOUT dummies, nested forwarding, expression temporaries, definition flags,
writable-overlap rejection, frozen two-index scalar actuals, fresh rank-one/rank-
two procedure locals, extreme bounds and storage limits. A matrix multiplication
acceptance case uses explicit loops, without claiming MATMUL support.

Rank-two sections, rank-three and higher arrays, dynamic bounds, array declaration
initializers, array results, explicit-shape/assumed-size dummies, constructors,
RESHAPE, reduction/transformational intrinsics and unlisted features remain
unsupported. See [RANK-TWO-ARRAYS.md](RANK-TWO-ARRAYS.md),
[ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md) and README.md for the contract.
Functions retain IN-only arguments and scalar results. Whole-program declared
array storage, per-frame storage and per-call array actuals each retain the
65,536-element limit.

Passing these selected tests is not a full-language conformance claim. Windows
has not been executed; the archive is a portable source release, not a prebuilt
Windows binary or a production hostile-input sandbox.

## Preservation and provenance

All **1,146 prior Fortran source fixtures**, **16 prior examples** and **467
vendored files** are byte-identical to 0.8.0. No file from the prior archive was
removed. The prior rank-two declaration, whole-rank-two assignment and local-
array fixtures now have success expectations; their source bytes are unchanged.
Two native forged-rank checks now use rank three to preserve their invalid-rank
purpose. Historical verification reports and original licenses/notices remain.

No additional vendor patch was required. The adapter handles documented missing
occurrence metadata using exact declaration identity, declared type/rank/kind
and both scalar INTEGER subscript trees, with independent mutation coverage.
The pinned FortFront commit and seven retained producer patches are unchanged.
