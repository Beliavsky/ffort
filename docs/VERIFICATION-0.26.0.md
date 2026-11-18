# Verification of prototype 0.26.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

The candidate source ZIP was extracted into a new directory whose path contains
spaces. `python3 scripts/verify.py` built without a build cache or network
dependency download under the default 8 MiB stack limit and completed all native,
CLI and source suites. Shipped implementation, vendor files, test sources,
examples, FPM configuration and verifier match the tested extraction byte for
byte. Report copies and SHA-256 manifest were assembled afterward; the final ZIP
was checked for source identity, manifest integrity and absence of compiled files.
The CLI reports version 0.26.0.

An earlier clean run correctly reached the new utilities boundary but exposed a
second test assertion still expecting the old 595:45 diagnostic. That assertion
was updated to 597:54 without changing the original Fortran source or the
implementation. The final source archive was rebuilt and the entire verifier
rerun from a fresh extraction. The earlier diagnostic log is retained separately.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_character | 35/35 | 30 | 0 | 5 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatables | 45/45 | 17 | 0 | 28 |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| character_arrays | 49/49 | 48 | 0 | 1 |
| character_parameters | 58/58 | 57 | 0 | 1 |
| character_procedures | 35/35 | 35 | 0 | 0 |
| class_type_bound | 44/44 | 40 | 0 | 4 |
| control_flow | 57/57 | 25 | 0 | 32 |
| count_bounds | 42/42 | 33 | 0 | 9 |
| count_pack_integration | 1/1 | 1 | 0 | 0 |
| count_pack_reshape_integration | 1/1 | 1 | 0 | 0 |
| defined_operators | 19/19 | 19 | 0 | 0 |
| defined_operators/optional_operands | 6/6 | 6 | 0 | 0 |
| derived_date_independent | 73/73 | 73 | 0 | 0 |
| derived_select_integration | 18/18 | 18 | 0 | 0 |
| derived_types | 43/43 | 38 | 0 | 5 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
| forall | 85/85 | 39 | 0 | 46 |
| formatted_arrays | 47/47 | 25 | 0 | 22 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| hyperbolic_intrinsics | 32/32 | 32 | 0 | 0 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| location_intrinsics | 58/58 | 55 | 0 | 3 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| logical_intrinsics | 41/41 | 35 | 0 | 6 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| module_use | 26/26 | 26 | 0 | 0 |
| mutable_modules | 42/42 | 33 | 0 | 9 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| optional_arguments | 31/31 | 31 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| release025_integration | 3/3 | 3 | 0 | 0 |
| release026_integration | 6/6 | 6 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **4443/4443** | **3925** | **83** | **435** |

Zero failures. These are logical source cases, not process counts. Direct GNU
checks include executions, explicit compile-only assertions and required compile
rejections. Compile-only is not execution agreement. SIMPLE lowered to PURE is
explicitly weaker. RESHAPE's nonasserted GNU compilation observations are not
counted as direct checks. Known GNU discrepancies use independent interpreter
expectations and are identified separately below.

Additional checks:

- All 93 native Fortran programs, 17 CLI/resource contracts and
  277 Python harness self-tests pass, plus eight source-partitioner checks.
- Eight metadata CLI cases and a GNU execution comparison cover a source with
  551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- The independent kind model checks 5,488 SELECTED_REAL_KIND calls in 69 programs;
  108 additional section-association cases match GNU and the numerical matrix
  checks 272 values.
- All 4826 pre-existing native/corpus/example Fortran sources from 0.25
  remain byte-for-byte unchanged. Newly legal expectations are promoted in
  manifests without changing the original source fixtures.
- New vendor patches 0040, 0041 and 0042 replay against 0.25 and reproduce all
  457 vendor files exactly. Earlier patches, MIT license and attribution remain.
  The standalone upstream FortFront test suite was not executed.

## New feature checks

Allocatable CHARACTER has 35 focused source cases: 20 GNU execution comparisons,
five compile-only checks, five required compiler rejections and five
interpreter-only safety checks. Fixed, assumed and deferred lengths are covered
through rank-one/rank-two allocations, whole-array assignment, dummy entry and
copyback, array results, zero elements, undefined values and resource limits.
Sixteen native adapter/runtime mutation rejections preserve independent
metadata validation. Original `set_alloc_character_vec` and
`set_alloc_character_mat` bodies are verified against source hashes before use.

One compile-only case checks an empty explicitly typed CHARACTER constructor:
the interpreter retains lengths 6 then 2, while GNU Fortran 14.2 reports zero.
This is an independently specified length check, not GNU execution agreement.
Typed ALLOCATE of zero-sized CHARACTER arrays is separately compared with GNU.
The pre-existing empty-concatenation CHARACTER PARAMETER GNU discrepancy remains
documented in the preserved 0.25 report and excluded from direct GNU assertions.
Scalar allocatables, OPTIONAL CHARACTER, substrings, dynamic explicit-length
dummies, broader allocation specifiers and deferred-length PACK/RESHAPE remain
unsupported. See [ALLOCATABLE-CHARACTER.md](ALLOCATABLE-CHARACTER.md).

FORALL checks one or two INTEGER indices, independent frozen bounds, optional
frozen masks, frozen left-hand mappings, simultaneous RHS evaluation, overlapping
sections and duplicate destinations, statement ordering, index restoration,
empty iterations, wide bounds, checked work budgets, purity and invalid syntax.
The native FORALL test adds 137 checks and independently mutates retained IR/AST metadata. Exact original
utility bodies are preserved in new wrappers; they do not constitute complete
original-module execution. A minimum INTEGER(8) stride case is verified by an
independent expected-output policy because GNU 14.2 disagrees at that extreme.
See [FORALL.md](FORALL.md) for the supported subset and exact checks.

Rounding/LOG10 has 78 focused cases: seven GNU execution programs, 40 required
GNU-invalid rejections, 14 GNU-legal unsupported boundaries and 17 runtime
safety checks. A sweep compares 7,056 INTEGER results exactly. The native test
contains 850 assertions, including independent producer, adapter and runtime
malformations and nontrivial LOG10 precision checks. The unchanged original
`floor_10` and `ceiling_10` bodies execute in a new driver.
See [ROUNDING-INTRINSICS.md](ROUNDING-INTRINSICS.md).

Six cross-feature cases combine the new features. Five execute against GNU and
literal expected values; one checks duplicate CHARACTER destinations with a
compile-only GNU baseline. They include exact original `munge`, `floor_10`,
`ceiling_10` and `set_alloc_character_vec` bodies, deferred-length snapshots,
allocatable dummy forwarding, typed constructors, rounding in FORALL RHSs and
zero-sized descriptors. Formatted CHARACTER records are compared byte for byte.
The module wrappers and drivers are new and separately identified.

## Exact original utilities boundary

The complete original file remains exactly 338,883 bytes with SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
It passes source/metadata capacity, inferred-length CHARACTER PARAMETER and
allocatable CHARACTER declarations. Both check and run modes now reject at:

`597:54: OPTIONAL supports scalar INTEGER, REAL and LOGICAL dummies only`

Both return status 1 with no stdout. This is progress from the 0.25 boundary at
595:45, not a claim that the full utilities library executes. Rank-three arrays,
OPTIONAL CHARACTER, external/formatted file I/O, unlisted intrinsics and other
unsupported bodies remain separate blockers.

The untouched file also compiled and ran with GNU Fortran 14.2 using
`-fcheck=all` in default mode. It exits zero at the original driver's intentional
`check_all_equal([2,3],...)` STOP. Logs and source hashes are retained under
`docs/verification/0.26.0/original-gnu/`. No random-valued output is claimed to
match byte for byte. The original's nonstandard ISNAN usage remains outside
strict standard-mode validation.

## Pinned M_intrinsics whole-program survey

All 249 unchanged files at pinned commit
`fc14233036d910e3678d350efc24609e11475067` were rerun against the final clean
0.26 executable: four complete programs pass and match GNU, 232 nonempty
programs reject, and 13 files are empty placeholders. Complete passes remain
`demo_dot_product`, `demo_kind`, `demo_mod` and `demo_modulo`; there are no
new complete passes, regressions, accepted-output mismatches, crashes or timeouts.

Fourteen first diagnostics changed: EOSHIFT gets past LOG10, FLOOR gets past
FLOOR before stopping at EPSILON, and twelve scalar deferred CHARACTER
allocatable examples receive a more specific unsupported-shape diagnostic.
Those twelve are not supported scalar allocations. All three separate RESHAPE
probes still match GNU. The unchanged demo_unpack still first rejects reserved
identifier `result` at 16:18; probe success is not full-example support.

See [the survey report](verification/0.26.0/m-intrinsics/REPORT.md), compact
CSV/JSON catalogs and compiler/reference classifications. Full original sources,
licensing and per-case logs are in the separate reproducible archive
`m-intrinsics-0.26-verification.zip`.

## Reproduction and scope

Run `python3 scripts/verify.py` with fpm and gfortran on PATH. Bash and PowerShell
wrappers are retained. Windows-friendly paths and verifier code are provided,
but Windows execution is unverified. Debug checks passing do not establish
complete Fortran conformance or a process-memory sandbox. Strict independent
source, producer metadata, adapter and runtime checks remain enabled.

Detailed machine-readable results are in tests/ and
`docs/verification/0.26.0/`; earlier release reports and provenance are retained.
