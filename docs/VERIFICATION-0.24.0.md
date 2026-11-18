# Verification of prototype 0.24.0

Recorded 15 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Clean source archive verification

The source ZIP was extracted into a new directory whose path contains spaces.
Final PARAMETER-descriptor regression fixtures were added before native test
discovery/compilation. `python3 scripts/verify.py` built without a build cache or dependency download
under the default 8 MiB stack limit and completed every native and source suite.
Earlier integration runs exposed one stale full-utilities boundary assertion and
a real module PARAMETER-array descriptor regression. Both were corrected before
this fresh final extraction/build. The original regression fixture was retained
and passed. Earlier diagnostic logs and the final aggregate log are included.
The shipped implementation, vendor files, tests, examples, FPM configuration and
verifier match that tested extraction. Report copies, documentation and the
SHA-256 file manifest were finalized afterward.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatables | 45/45 | 16 | 0 | 29 |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| character_arrays | 49/49 | 48 | 0 | 1 |
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
| formatted_arrays | 47/47 | 25 | 0 | 22 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| hyperbolic_intrinsics | 32/32 | 32 | 0 | 0 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| location_intrinsics | 58/58 | 55 | 0 | 3 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| logical_intrinsics | 40/40 | 33 | 0 | 7 |
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
| release_integration | 10/10 | 10 | 0 | 0 |
| reshape | 88/88 | 33 | 0 | 55 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| utilities_slices | 33/33 | 31 | 0 | 2 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **4099/4099** | **3632** | **83** | **384** |

Zero failures. These are logical source cases, not process invocations. Direct
GNU checks include execution, explicit compilation-only checks and expected
compile rejection. Compile-only is not an execution comparison. SIMPLE references
lowered to PURE are explicitly weaker. RESHAPE has 33 execution comparisons;
its other 55 GNU compilations are observations, not assertions of acceptance or
rejection, and remain conservatively in the final column.

Additional checks:

- All 81 native Fortran programs, 17 CLI/resource contracts and
  277 Python harness self-tests pass. Eight source-partitioner checks pass.
- Eight metadata CLI cases pass separately from the source table. The synthetic
  source with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols
  executes against GNU; the independent active runtime depth limit stays 64.
- The independent kind model checks 5,488 SELECTED_REAL_KIND calls in 69 programs.
  A further 108 section-association cases match GNU, and the numerical matrix
  checks 272 values with exact stdout agreement.
- Vendor patches 0036 and 0037 replay against 0.23.0 and reproduce all 457 vendor
  files exactly. They repair allocation-child ownership and provide a default-off
  strict semantic option for allocatable assignment. Earlier patches, licenses and
  attribution are preserved. The standalone upstream FortFront suite was not run.
- Of 4,554 pre-existing native/corpus/example Fortran sources from 0.23.0,
  4,553 remain byte-for-byte unchanged. The only change updates the native formatted
  output test from rejecting an array to checking its new supported result. All
  existing source corpus fixtures, examples and the full original utilities are
  unchanged; formerly unsupported expectations are promoted in manifests.

## New features and combined checks

Numeric allocatable storage has 45 source cases; assignment/results have 26 and
allocatable dummy descriptors have 28. They cover explicit allocation, STAT,
deallocation, module/local lifetimes, lower bounds, zero extents, rank-two shapes,
assignment reallocation and overlap, conversion, fresh function results, explicit
INTENT IN/OUT/INOUT, nested forwarding, undefined values, conservative aliases,
PURE boundaries and caller/frame limits. Native tests mutate allocation and dummy
metadata and verify repeated-run state and the producer option's unchanged default.

Formatted arrays have 47 cases, including the complete unchanged upstream
`demo_dot_product.f90`. Successful cases compare output bytes with GNU; that
upstream example's final list-directed record compares tokens. Coverage includes
array element order, integer/real/logical/character edits, results and sections,
flat-format reversion, empty data, literals, internal WRITE, defined-output
callbacks, resource limits and failure-atomic rendering.

Seven additional synthetic cases combine OUT/INOUT descriptors, allocatable
results and PACK, mutable rank-two module arrays, sections/location/reductions,
REAL(8) hyperbolics, zero extents, assignment reallocation and internal WRITE.
The five success cases match GNU byte-for-byte; two undefined/unallocated cases
verify that a failing formatted statement leaks no partial records.

The `alloc_sub_vec_real` and `alloc_sub_vec_int` procedure texts are retained from
the original utilities after CRLF-to-LF normalization, with a new module wrapper
and execution driver. Their source lines and hashes are recorded separately in
`allocatable_dummies-utility-provenance.json`. This is original-body coverage,
not execution of the original full module or original main. Earlier original-body
and cross-feature suites remain enabled unchanged.

## Independent M_intrinsics compatibility survey

All 249 pinned example entries were rerun on the same final clean executable:
236 nonempty programs and 13 empty placeholders. Four complete unchanged originals
(DOT_PRODUCT, KIND, MOD and MODULO) execute and match GNU; 232 are explicitly
rejected. DOT_PRODUCT is newly supported. No previous pass regressed, and no
accepted-output mismatch, interpreter crash or timeout was observed. See the
[survey report](verification/0.24.0/m-intrinsics/REPORT.md) for blocker changes,
source/compiler limitations and supplemental probes. Complete independent logs
and pinned sources are in `m-intrinsics-0.24-verification.zip`. These survey cases
are separate from the release-source table above.

## Full original utilities boundary

The untouched 338,883-byte utilities source passes source-preservation and exact
reconstruction checks. It passes the numeric allocatable module declarations.
Both check and run modes reject at line 499, column 30 with status 1 and no output:
`Assumed-length CHARACTER requires a dummy argument`. This declaration is an
inferred-length CHARACTER PARAMETER, not an invalid Fortran declaration. The full
original file still does not compile or execute in this interpreter. CHARACTER
procedure composition, rank three, broader control flow/intrinsics and I/O remain
gaps. No unsupported body is skipped.

GNU Fortran was rerun on the unchanged full original using its default mode and
`-fcheck=all`: compile and run both exit 0. Its original driver intentionally ends
with the unequal-values diagnostic and ordinary STOP. Strict F2018 compilation
is not equivalent because the source uses GNU extensions. No source rewrite was made.

## Reproduce

Put GNU Fortran, fpm and Python 3 on PATH and run `python3 scripts/verify.py`.
Bash and PowerShell wrappers use that same portable verifier. Per-suite results
remain under tests/. Clean log, summary and provenance are in
`docs/verification/0.24.0/`; the previous report is `VERIFICATION-0.23.0.md`.

This remains a bounded interpreter prototype, not general modern Fortran support
or a production security sandbox. Windows source compatibility is intended but
Windows was not executed. See ALLOCATABLES.md, ALLOCATABLE-ASSIGNMENT.md and
FORMATTED-ARRAYS.md for exact contracts and exclusions.
