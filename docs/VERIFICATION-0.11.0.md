# Verification of prototype 0.11.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. GNU source-corpus commands use
`-std=f2018 -pedantic-errors -fcheck=all -O0` where applicable.

## Clean extraction and full verification

The complete release candidate was archived, extracted into a fresh directory
whose path contains spaces, and rebuilt without a build cache or network
dependency downloads using `python3 scripts/verify.py`. The command exited zero
and every aggregate check passed. Final executable source, tests, fixtures and
build files match that extraction. Thirteen combined result files and the
aggregate log come from this clean run. Verification documentation and the
file manifest were finalized afterward; no executable source changed.

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
| Array intrinsics | 234/234 | 234 | 0 |
| **Total** | **1,783/1,783** | **1,669** | **114** |

There are **zero failures**. Applicable GNU checks include execution,
compilation-only checks and expected compile rejections, not 1,669 successful
executions. The new 234-case suite has 167 GNU executions, 49 compilation-only
checks and 18 expected GNU compile rejections. Safety-policy cases are checked
against the interpreter's explicit contract. Unsupported but valid Fortran is
compiled by GNU without treating the interpreter's rejection as a GNU execution
proof. Explicit skips are not compiler passes.

In addition:

- All **19 native Fortran test programs**, **17 CLI/resource contracts** and
  **139 runner self-tests** pass.
- The new adapter test accepts a baseline and rejects **25 deliberate AST/IR
  disagreements**. The new runtime test executes a baseline, rejects **19
  malformed IR variants**, and enforces a shared-budget limit.
- **108/108 generated nested-section programs** match independent Python list
  expectations and GNU execution, including bounds, empty arrays, strides,
  forwarding and copy-back.
- The arithmetic matrix produces **272 formatted REAL32/REAL64/mixed-kind
  values exactly matching GNU Fortran byte for byte**.
- The new `examples/array_intrinsics.f90` runs successfully; the existing
  implicit-main, parameter, module and Black-Scholes examples are retained.

See [the full clean-room log](verification/0.11.0/clean-room-full-verification.log),
`tests/*/results.json`, the arithmetic/section matrix result files, and
[the independent array-intrinsic suite](../tests/array_intrinsics_independent/README.md).
The archive contains source, tests, documentation and the pinned dependency,
not a compiler installation, cached objects or prebuilt executable.

## New feature coverage

The independent suite checks all four reductions on INTEGER, REAL(4) and REAL(8)
rank-one/rank-two arrays; scalar and array masks; positional MASK without DIM;
both DIM directions and runtime DIM changes; lower bounds; reversed/strided and
rank-reducing sections; nested transformations and scalar expansion; overlap-safe
assignment; assumed-shape procedures; empty input and output dimensions; all
empty identities; shape-only inquiries; type/kind promotion and exact dummy-kind
checks; numeric and LOGICAL DOT_PRODUCT; all three MATMUL rank combinations;
zero inner/outer dimensions; and generated independent matrix/section cases.

Negative checks include wrong types/ranks, keyword arguments, missing/extra
arguments, shape mismatch, invalid DIM, uninitialized values, selected/unselected
MASK data, invalid section descriptors, integer and real intermediate overflow,
atomic failed PRINT, result-element limits and execution-budget exhaustion.
A separate source review checked shape/type/kind derivation, DIM/MASK association,
column-major indexing, rounding and overflow, and eager logical reads without
finding an additional defect.

## Deliberate boundaries and evaluation policy

This remains a restricted interpreter prototype, not a full modern Fortran
implementation or hostile-input sandbox. The six new intrinsics use positional
arguments only. Rank three and higher, complex/character reductions, unsupported
kinds, array constructors, allocation and array procedure results remain outside
the subset. Array-intrinsic result extents are resolved at execution; invalid
DIM values fail at runtime even when written as literals.

All result shapes are capped before traversal. Numeric product/addition
intermediates are checked rather than wrapping or retaining infinity. Masked-out
ARRAY data is not evaluated; an empty output array evaluates no scalar MASK or
other data values. Scalar identities for empty inputs do evaluate scalar MASK.
LOGICAL products evaluate both input values even after the result becomes true.
Floating reductions use deterministic ordered operations in the result kind;
Fortran permits other reduction orders, so selected test agreement is not a
universal bitwise promise. See [ARRAY-INTRINSICS.md](ARRAY-INTRINSICS.md).

Windows has not been executed. The source and Python verification runner retain
their portable build interfaces. Concurrent in-process FortFront compilations
remain unsupported because upstream semantic state is process-global. No
upstream-wide test-suite result, compiler backend or production isolation claim
is made.

## Preservation and reproducibility

All **467 files under vendor/**, all **18 prior examples**, all **17 prior native
test sources**, LICENSE and THIRD_PARTY_NOTICES.md compare byte-for-byte with
0.10.0. Previous source fixtures and runner expectations are retained. FortFront
remains pinned to commit `9a5896a1fce32c394fd02dd1da1bd261ea7a646f` with the same
previously documented local patches; no new vendor patch was needed. The FPM
manifest retains its dependency/build configuration with the release version
updated to 0.11.0. Earlier verification reports and logs remain included.

After packaging, every entry of MANIFEST.sha256 is verified from a separate
final extraction. The native `--version` reports 0.11.0. Reproduce with:

```sh
fpm build
fpm test
python3 scripts/verify.py
```
