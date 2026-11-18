# Verification of prototype 0.28.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity, and absence of compiled files were verified. The CLI reports 0.28.0.

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
| character_intrinsics | 37/37 | 36 | 0 | 1 |
| character_parameters | 58/58 | 57 | 0 | 1 |
| character_procedures | 35/35 | 35 | 0 | 0 |
| character_search | 58/58 | 58 | 0 | 0 |
| character_substrings | 35/35 | 34 | 0 | 1 |
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
| optional_character | 34/34 | 34 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| optional_numeric_arrays | 67/67 | 41 | 0 | 26 |
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_three | 50/50 | 45 | 0 | 5 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| recursion | 31/31 | 17 | 0 | 14 |
| release025_integration | 3/3 | 3 | 0 | 0 |
| release026_integration | 6/6 | 6 | 0 | 0 |
| release027_integration | 10/10 | 10 | 0 | 0 |
| release028_integration | 7/7 | 7 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **4832/4832** | **4233** | **83** | **516** |

Zero failures. Counts represent logical source cases, not process invocations. Direct GNU checks include execution comparisons, explicit compile-only assertions and required compiler rejections. Compile-only is not execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies are classified separately, not counted as GNU execution agreement.

- 109 native Fortran programs, 289 Python harness self-tests, 17 CLI/resource contracts and eight partitioner self-checks pass.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases, and 272 numerical-matrix values.
- All 5155 existing Fortran native/corpus/example files from 0.27 are present; 5138 preserve exact bytes. The 17 changed native mutation tests adapt descriptor widths or newly supported boundaries. All existing corpus/example Fortran source bytes remain unchanged. See source-preservation.json.
- Vendor patches 0047 and 0048 replay with zero fuzz against the exact 0.27 vendor tree and reproduce all 457 vendor files byte for byte. WHERE parser metadata and SCAN/VERIFY type metadata remain separate documented corrections. MIT notices and earlier patch history remain. The standalone upstream FortFront suite was not run.

The first clean pass exposed two test-maintenance issues: an old full-source boundary string and a missing explanatory note in deterministic fixture generation. Both were corrected without changing interpreter code or existing Fortran fixtures; the complete final verifier was rerun from a fresh extraction. The earlier logs are retained.

## New bounded features and source provenance

- Rank-three ordinary arrays: 50 focused cases, 45 GNU checks, five runtime safety-policy cases, 12 harness self-tests, 31 adapter metadata mutations and 12 direct-runtime checks. Explicit, automatic and assumed-shape arrays, third-axis indexing, rank-reducing sections, elemental operations and scalar-DIM inquiries are covered. Rank-three ALLOCATABLE arrays, reductions and transformations remain excluded. The original `tensor` body is preserved with line endings normalized inside a separate driver.
- Explicit recursion: 31 cases with 16 GNU executions, one compile-only check and 14 runtime-policy cases. RECURSIVE functions/subroutines retain independent activations, shared work accounting and a 64-frame limit. Every cycle participant must be explicit; RECURSIVE ELEMENTAL remains excluded. Exact original `set_alloc_int_vec` executes with lower/upper/both/no filters, empty cases and reverse sections. The existing original real/integer allocation slice now executes all four byte-preserved bodies.
- WHERE: 60 cases comprising 26 GNU differential cases, 17 source rejections, 13 runtime rejections and four interpreter-only policy checks, plus 137 native assertions and separate third-selector purity mutations. Masks remain rank one/two; rank-reduced rank-three sections compose correctly. Original `lag` and `madev` bodies are preserved, but their scaffolding is explicit: `check_all_equal` is a harness assertion, and `moving_average_data_good` implements only the equivalent NMA=0 branch. The original madev ratio-default MERGE reading undefined xmadev is an expected runtime rejection, not a claimed full routine success.
- SCAN/VERIFY: 58 cases with 24 GNU executions, 28 required GNU source rejections and six compile-only checks. An independent 2,080-value string matrix, 330 adapter/runtime mutations and 18 producer checks are retained. Two exact expressions from original `get_numbers` are tested in new drivers, not the entire routine.
- Seven combined release cases test recursive WHERE arithmetic with searches, rank-three search arguments and OPTIONAL BACK, empty zero-length CHARACTER cubes, negative third-axis WHERE sections, and explicit rank-three/impure WHERE boundaries. Five execute with GNU; two have compile-only GNU evidence.

## Untouched original utility file

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `1987:54: Only rank-one and rank-two ALLOCATABLE arrays are supported`. The complete original library still does not run in the interpreter. GNU Fortran compiles and runs the untouched original with -fcheck=all in its default extension mode; it exits zero at its intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects the original nonstandard ISNAN call. Original GNU logs are included in this release evidence.

## Limits and historical evidence

Earlier GNU ICE observations for CHARACTER/INDEX array edges remain documented and are not counted as agreement. Undefined-source and resource-policy cases intentionally avoid GNU execution. Original-body support, synthetic feature tests, and full-library execution are separate claims. Rank-four arrays, unsupported ALLOCATABLE shapes, unrestricted I/O, recursive ELEMENTAL and unlisted syntax/intrinsics still reject. The full M_intrinsics survey confirms four complete original passes, 232 explicit rejections and 13 empty files, with no regressions, mismatches, crashes or timeouts. COUNT and PACK advance to later unsupported features; neither becomes a full pass. All three retained RESHAPE probes match GNU. The comparison is retained under this release's m-intrinsics evidence. Historical 0.27 results remain in VERIFICATION-0.27.0.md and docs/verification/0.27.0.
