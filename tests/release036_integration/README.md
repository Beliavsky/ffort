# Release 0.36 independent composition checks

This suite combines bounded DIM/SIGN/LOG_GAMMA, PARITY, EPSILON/RADIX/TINY/HUGE,
and read-only numeric rank-two row gathering. It is additional integration
coverage, not a substitute for the focused feature or earlier release suites.

## Independent oracles and boundaries

The 32 source fixtures use fixed integer/logical/record oracles, elementary
mathematical identities, IEEE binary32/binary64 model constants, and independently
calculated log-factorial values. Expected results are never captured from either
the candidate or GNU. Every supported GNU execution must satisfy both the fixed
oracle and direct candidate/GNU comparison.

GNU Fortran is used in three explicit stages:

- 20 safe executions, including three standard-valid GNU-only subset boundaries.
- 10 compile-only probes: undefined/unallocated/absent operand metadata, candidate
  overflow/finite-value guards, undefined reductions, invalid row indices, and one
  documented GNU arithmetic discrepancy. None is claimed as runtime equivalence.
- Two invalid sources that GNU must cleanly reject.

GNU 14.2 computes variable `DIM(-HUGE(0_8),HUGE(0_8))` as 2, consistent with wrapped subtraction before clamping. The
mathematical result is zero because X is less than Y. The candidate's independent
zero oracle remains required, while this isolated case is GNU compile-only.
Ordinary INTEGER8 edge tests remain strict differential executions. The zero oracle
follows [Fortran 2018 DIM, J3/18-007r1 section 16.9.62](https://j3-fortran.org/doc/year/18/18-007r1.pdf#page=379).
The wrap explanation is an inference from behavior, not a compiler-source audit.

Successful synthetic output uses exact records except explicitly numeric/mixed
upstream-style output. Numeric comparison uses Decimal, exact integers, a 2e-6
relative tolerance, and **zero absolute tolerance**. Zero cannot pass as TINY.
Binary64 EPSILON/TINY/HUGE also have exact Boolean model checks. Signed-zero
semantics are checked through SIGN-to-integer outputs and native IEEE sign-bit
inspection. Mixed-token comparison checks every nonnumeric token exactly and is
not evidence for CHARACTER spacing or record fidelity.

Runtime-negative output is statement-atomic: the exact previously completed
`before` record is permitted and required; no part of the failing next record,
extra newline, or whitespace is accepted. Check-time rejection must emit no
stdout. Timeouts, signals, host-runtime diagnostics, missing diagnostics, compiler
warnings, and exit-status substitution all fail closed.

## Cross-feature coverage

- INTEGER8 gather → DIM → comparisons → PARITY, COUNT, SUM and model inquiries.
- Parenthesized materialized gather actuals whose allocatable INTENT(OUT) alias is
  deallocated/reallocated, followed by a second self-reallocation gather.
- A side-effecting IMPURE ELEMENTAL index function runs once per index element
  for each gather, with no repeated shape-evaluation effects or stale cache.
- REAL4 signed zero and REAL8 LOG_GAMMA over duplicated/reordered gathered rows.
- Empty gathered rows, empty logical masks, both PARITY DIM directions and model
  inquiries on zero-size expressions.
- Scalar model metadata without value/shape/function evaluation, including
  gathered undefined indices, unallocated arrays, absent OPTIONAL arguments,
  nested elementary calls and automatic specification bounds. Ordinary module-writing
  functions remain an existing unsupported effect boundary; the effect probes use
  supported IMPURE ELEMENTAL functions.
- Integer overflow, LOG_GAMMA poles and finite-value policy, undefined logical
  values after a true element, and out-of-bounds indices even with zero columns.
- Explicit boundaries for rank-three PARITY, model inquiries on derived
  components, scatter assignment, writable vector actuals and mismatched kinds.

## Preserved original sources

`original/filter_module.f90` contains the exact CRLF bodies of
`filter_matrix_rows` (23 lines, 1090 bytes), `true_pos_func` (13 lines, 328 bytes),
and `set_alloc_real_matrix` (7 lines, 303 bytes), from the retained
`tests/utilities_slices/source/xutilities.f90`. Module declarations, generic
interfaces and integration drivers are explicitly synthetic scaffolding. No
original body, dependency, comment, continuation or line ending is rewritten.
The original dependency closure is exercised through reallocation, filtering,
PARITY, model inquiries, DIM, SIGN and LOG_GAMMA.

Seven full unchanged M_intrinsics programs (DIM, SIGN, LOG_GAMMA, PARITY, FLOOR,
RADIX, TINY) are also compiled/executed with that same original utility module in
the source. Their upstream revision is
`fc14233036d910e3678d350efc24609e11475067`; the original MIT license is included.
This does not claim support for the complete utility library or M_intrinsics
corpus.

`original-source-map.json` records byte ranges, source line ranges, wrapper
positions, CRLF counts, sizes and SHA-256 values. The runner independently pins
all three body contracts and seven original-program hashes, checks the complete
closure and license, and verifies fixture/candidate/provenance integrity before
and after execution. A forged wrapper hash cannot conceal a changed body.

## Native public-IR evidence

`test/test_release036_composition.f90` mutates all eight intrinsic call families
and a gather nested in DIM. Adapter validation and direct program execution are
checked independently. Additional public-IR graphs are constructed without the
parser: DIM(SIGN(...)), model(LOG_GAMMA(0)) metadata suppression, signed-zero
SIGN, and PARITY/KIND. Malformed child metadata must fail even under an
unevaluated inquiry. Valid roots are rerun to expose stale state.

## Reproducibility

Run with a completed, immutable application build and explicit compiler:

```sh
python3 tests/release036_integration/test_runner.py
python3 tests/release036_integration/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
```

The runner snapshots and hashes the executable rather than racing a shared
build. Compiler invocations use strict Fortran 2018, `-pedantic-errors`, and
`-fcheck=all,no-array-temps`; only the expected temporary-array warning is
disabled. All other stderr remains checked.

`prepare_cases.py` regenerates only this new suite. Its self-test runs in an
isolated directory and requires byte-identical sources, manifest, provenance and
license. The adversarial harness self-tests additionally cover provenance
corruption, removed dependency bodies, changed original programs, candidate copy
races, nonfinite/wrong tokens, exact integer precision, tiny-versus-zero, exact
completed prefixes, and crash/timeout handling.
