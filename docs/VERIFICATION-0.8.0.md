# Verification of prototype 0.8.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU reference commands use
`-std=f2018 -pedantic-errors -fcheck=all` (source corpora also use `-O0`).

## Clean extraction and full verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. All aggregate checks pass.
All **1,687 implementation, test, fixture, manifest, example, verifier and vendored
source inputs** were compared byte-for-byte with that checked extraction before
final packaging. Only result evidence and documentation were updated afterward.

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
| **Total** | **1,144/1,144** | **1,037** | **107** |

There are **zero failures**. GNU checks include compilation/rejection and, where
specified, execution against independent expected results. Runtime-policy and
valid-but-unsupported cases are deliberately not presented as GNU execution
proofs. Explicit skips are not compiler passes.

In addition:

- **108/108 generated nested-section programs** match independent Python list
  expectations and GNU execution. They cover caller/dummy lower bounds, empty
  arrays, forward/reverse strides, nested forwarding and copy-back.
- The existing arithmetic matrix produces **272 formatted REAL32/REAL64/mixed-kind
  values exactly matching GNU Fortran byte for byte**.
- All **15 native Fortran test programs**, **17 CLI/resource contracts** and
  **99 runner self-tests** pass. The new native adapter suite includes an accepted
  baseline and 15 deliberate AST/IR mutations.
- `examples/argument_association.f90` independently passes check/run and GNU
  comparison: mean 3, sample standard deviation 1.581139, and final array
  `-2 -1 1 1 2` after reversed-section and scalar-element updates.

The checked clean debug executable SHA-256 is
`bec74cb4df1db23423ccde5eac6db8e34916f59dbda6b7bbe0440714473c7a18`.
This identifies the checked build, not a distributed binary; paths/debug metadata
can change the hash on another machine. The final ZIP was extracted and every
entry in MANIFEST.sha256 was verified after packaging.

## Added coverage and limits

The 145 new corpus cases contain 78 successful programs, 34 interpreter
runtime-policy cases, 28 invalid programs rejected by both implementations, and
5 standard-valid but unsupported programs rejected by this interpreter. Coverage
includes scalar OUT/INOUT and array-element actuals, assumed-shape IN/OUT/INOUT
arrays, partial definition flags, nested forwarding, expression temporaries,
read-only aliases and rejected writable overlap, frozen subscripts/triplets,
nonunit and extreme lower bounds, logical/real32/real64 values, imported named
kinds, array inquiries, PURE subroutines and resource boundaries. The numerical
mean/stddev acceptance program uses an IN array and two scalar OUT results.

See [ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md) and the current README for
the complete contract. Array dummies are rank-one assumed-shape only; procedure
locals/results remain scalar. Functions retain IN-only arguments. Writable
CHARACTER, optional/keyword arguments, explicit-shape/assumed-size dummies,
multidimensional arrays, dynamic dummy lower bounds, mutable host/module data
and recursion remain outside the subset. Overlapping direct actual bindings are
conservatively rejected if either dummy is writable. Inquiries return scalar
INTEGER results, require DIM=1 when supplied, and require DIM for LBOUND/UBOUND.

Passing these selected tests is not a full-language conformance claim. Windows
has not been executed; the archive is a portable source release, not a prebuilt
Windows binary or a production hostile-input sandbox.

## Preservation and provenance

All **1,001 prior Fortran source fixtures** are byte-identical to 0.7.0 and no
prior archive file has been removed. The formerly unsupported SIZE fixture now
has a success expectation. The old literal-to-OUT negative remains rejected and
now has a GNU rejection oracle instead of a skip. Both fixture sources are
unchanged. Historical reports, earlier requested examples and original licenses
are retained.

**456 of 457 existing vendored files** are byte-identical. The single producer
file change is retained as patch 0007, replayed against the exact 0.7.0 bytes and
compared byte-for-byte with the final vendor source. It corrects array dummy
rank and actual-array/element/section kind inference. The private recognizer and
required FortFront AST/binding/type cross-check remain separate. Patch details,
checksums and the source-preservation report are under `verification/0.8.0`.
Root and FortFront MIT licenses are unchanged; attribution is retained. No
upstream authorship, endorsement or whole-upstream-suite pass is claimed.

Current evidence is the eight `tests/*/results.json` files, argument-section and
arithmetic matrix reports, example report and
`verification/0.8.0/clean-room-full-verification.log`. Historical evidence remains
provenance. The ZIP excludes compilers, binaries, build caches and Python bytecode.
MANIFEST.sha256 covers every included file except itself.
