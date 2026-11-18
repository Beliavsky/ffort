# Verification of prototype 0.23.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Clean source archive verification

The source ZIP was extracted into a new directory whose path contains spaces.
`python3 scripts/verify.py` built it without a build cache or dependency download
and completed every native and source suite under the default 8 MiB stack limit.
The shipped implementation, vendor files, tests, examples, FPM configuration and
verifier match that tested extraction. Report copies, documentation and the
SHA-256 file manifest were finalized afterward.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
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
| **Total** | **3946/3946** | **3548** | **83** | **315** |

Zero failures. These are logical source cases, not process invocations. Direct
GNU checks include execution, explicit compilation-only checks and expected
compile rejection. Compile-only is not an execution comparison. SIMPLE references
lowered to PURE are explicitly weaker. RESHAPE has 33 execution comparisons;
its other 55 GNU compilations are observations, not assertions of acceptance or
rejection, and remain conservatively in the final column.

Additional checks:

- All 76 native Fortran programs, 17 CLI/resource contracts and
  277 Python harness self-tests pass. Eight source-partitioner checks pass.
- Eight metadata CLI cases pass separately from the source table. The synthetic
  source with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols
  executes against GNU; the independent active runtime depth limit stays 64.
- The independent kind model checks 5,488 SELECTED_REAL_KIND calls in 69 programs.
  A further 108 section-association cases match GNU, and the numerical matrix
  checks 272 values with exact stdout agreement.
- Vendor patches 0034 and 0035 replay against 0.22.0 and reproduce all 457 vendor
  files exactly. Only the declaration accessibility resolver and location-intrinsic
  metadata query change. Earlier patches, licenses and attribution are preserved.
  The standalone full upstream FortFront suite was not run.
- All 4,443 pre-existing native/corpus/example Fortran sources from 0.22.0 remain
  byte-for-byte unchanged. Previously unsupported feature expectations were promoted
  in manifests/generators without changing their original source fixtures.

## New features and combined checks

Mutable modules have 42 source cases: 22 GNU executions, four compile-only checks,
seven GNU compile rejections and nine safety-only cases. Coverage includes shared
state across calls, private/public data, imports, kinds, arrays, undefined values,
INTENT(OUT), alias guards, PURE/SIMPLE boundaries, and defined formatted-output
callbacks updating the same module store. Native tests check reset on each top-level
execution, forged metadata and producer PUBLIC/PRIVATE resolution.

MINLOC/MAXLOC have 58 source cases: 27 GNU executions, six compile-only checks,
22 GNU compile rejections and three safety-only cases. Native coverage adds 331
adapter/runtime assertions and seven producer checks. Supported numeric rank-one/two
sources include DIM, MASK, KIND and BACK, plus bounded DIMENSION attributes.
GNU 14.2 returns a masked-out location in one rank-two MASK/BACK example. That
GNU result is recorded, not used as an oracle. A separate explicit-loop reference
confirms the expected result; the case remains compile-only in the GNU count.
See `tests/location_intrinsics/oracle-discrepancy.json` for the exact evidence.

RESHAPE has 88 source cases and 64 native assertions. Constant rank-one and
rank-two declaration/PARAMETER initializers now use bounded shape evaluation,
with independent per-axis validation. Cases cover supported types/kinds,
ORDER/PAD, constant sections, empty results and oversized/invalid shapes. The
original M_intrinsics demo_unpack declaration slice is preserved and hashed;
it does not establish support for UNPACK or the original full example.

The release-integration suite has ten cases. Its new combined program retains
exact original IMINLOC and VECTOR bodies while composing mutable module arrays,
rank-two RESHAPE initializers, DIMENSION, location DIM/MASK/BACK, reversed and empty
sections, and persistent writes. Hashes and body inclusion are checked. Three
additional cases check shape/constancy rejection and nonevaluating KIND over
undefined module storage. Wrappers and drivers are new, not the original main.
Earlier original COUNT/PACK/RESHAPE and other utility-body replays remain enabled.

## Independent M_intrinsics compatibility survey

All 249 pinned example entries were checked on the same final executable:
236 nonempty programs and 13 empty placeholders. Three unchanged originals
(KIND, MOD and MODULO) execute and match GNU; 233 are explicitly rejected.
No previous pass regressed, and no accepted-output mismatch, interpreter crash
or timeout was observed. Eight first blockers advance without changing the
full-program pass count. All three supplemental RESHAPE probes execute and
match GNU; two declaration probes were rejected in 0.22. The full demo_unpack
now reaches reserved identifier `result` at 16:18, beyond its initializers.
The [survey report](verification/0.23.0/m-intrinsics/REPORT.md), catalog and
comparison are included. Full independent logs and pinned sources are in the
separate `m-intrinsics-0.23-verification.zip`. These survey cases are reported
separately, not added to the release-source table above.

## Full original utilities boundary

The untouched 338,883-byte utilities source passes source-preservation and exact
reconstruction checks. It passes mutable declarations at lines 493–494. Both
check and run modes reject at line 495, column 10 with status 1 and no output:
`Unsupported declaration attribute`. This is `integer, allocatable :: comb_mat(:,:)`.
The full original file still does not compile or execute in this interpreter.
Allocatable storage, CHARACTER array procedure composition, rank three, broader
control flow/intrinsics and I/O remain gaps. No unsupported body is skipped.

GNU Fortran was rerun on the unchanged full original using its default mode and
`-fcheck=all`: compile and run both exit 0. Its original driver intentionally ends
with the unequal-values diagnostic and ordinary STOP. Strict F2018 compilation
is not equivalent because the source uses GNU extensions. No source rewrite was made.

## Reproduce

Put GNU Fortran, fpm and Python 3 on PATH and run `python3 scripts/verify.py`.
The Bash and PowerShell wrappers run that same portable verifier. Per-suite
results remain under tests/. The clean log, summary and provenance are in
`docs/verification/0.23.0/`; the previous report is `VERIFICATION-0.22.0.md`.

This remains a bounded interpreter prototype, not general modern Fortran support
or a production security sandbox. Windows source compatibility is intended but
Windows was not executed. See MUTABLE-MODULES.md, LOCATION-INTRINSICS.md and
RESHAPE.md for the precise contracts.
