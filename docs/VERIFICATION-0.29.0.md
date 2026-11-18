# Verification of prototype 0.29.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity, and absence of compiled files were verified. The CLI reports 0.29.0.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_character | 35/35 | 30 | 0 | 5 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatables | 45/45 | 18 | 0 | 27 |
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
| intent_spelling | 31/31 | 29 | 0 | 2 |
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
| rank_three_allocatables | 25/25 | 20 | 0 | 5 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| recursion | 31/31 | 17 | 0 | 14 |
| release025_integration | 3/3 | 3 | 0 | 0 |
| release026_integration | 6/6 | 6 | 0 | 0 |
| release027_integration | 10/10 | 10 | 0 | 0 |
| release028_integration | 7/7 | 7 | 0 | 0 |
| release029_integration | 12/12 | 11 | 0 | 1 |
| release_integration | 10/10 | 10 | 0 | 0 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| shape_intrinsic | 32/32 | 31 | 0 | 1 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **4932/4932** | **4325** | **83** | **524** |

Zero failures. Counts represent logical source cases, not process invocations. Direct GNU checks include execution comparisons, explicit compile-only assertions and required compiler rejections. Compile-only is not execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies are classified separately, not counted as GNU execution agreement.

- 113 native Fortran programs, 313 Python harness self-tests, 17 CLI/resource contracts and eight partitioner self-checks pass.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases, and 272 numerical-matrix values.
- All 5369 existing Fortran native/corpus/example files from 0.28 are present; 5369 preserve exact bytes. The preservation report identifies any changed files and their purpose. All existing native/corpus/example Fortran source bytes remain unchanged. See source-preservation.json.
- Vendor patches 0049 and 0050 replay with zero fuzz against the exact 0.28 vendor tree and reproduce all 457 vendor files byte for byte. INTENT continuation metadata and SHAPE type metadata remain separate documented corrections. MIT notices and earlier patch history remain. The standalone upstream FortFront suite was not run.

## New bounded features and source provenance

- Numeric/CHARACTER rank-three allocatable arrays: 25 focused cases, 20 direct GNU checks, five interpreter-only policy cases, 12 harness self-tests and 38 native malformed-descriptor rejection checks. Allocation/deallocation, descriptor dummies, OPTIONAL forwarding, module state, assignment reallocation, CHARACTER lengths, zero extents, bounds and allocatable results are covered. LOGICAL/scalar allocatables, ranks above three, SOURCE/MOLD/ERRMSG and multiple-target allocation remain excluded.
- INTENT(IN OUT): 31 focused cases with 15 GNU executions, one compile-only boundary, 13 GNU source rejections and two policy cases, plus 151 native assertions. Continuations, comments and grouped declarations retain exact declaration identity, alias and purity checks. The original set_offdiagonal body preserves all 366 bytes, including CRLF, and executes with square, nonsquare, empty and noncontiguous inputs.
- SHAPE: 32 focused cases with 18 GNU executions, ten required GNU source rejections, three compile-only checks and one unallocated-source policy skip. 337 native adapter/runtime assertions and seven producer cases verify descriptor, kind and rank metadata. Scalar results are zero-length vectors; intrinsic arrays through rank three and INTEGER result kinds 4/8 are supported. Four original conformity helpers are preserved with normalized line endings and tested: conform_real_1d, conform_real_2d, conform_real_3d, conform_optional_real_2d. This does not establish support for the whole combine_mat_tensor_real routine or its dependency graph.
- Twelve release composition tests (eight GNU execution comparisons, two compile-only checks, one GNU syntax rejection and one safety-policy skip; 12 harness self-tests) combine allocated SHAPE inquiries, rank-three sections, OPTIONAL and continued IN OUT descriptor forwarding, assignment reallocation, deferred CHARACTER lengths, empty extents, recursive result lifetimes, STAT invariants and WHERE rank-reduced sections. Their README and manifests distinguish independent GNU execution, compile-only boundaries and interpreter-only safety checks. Observed GNU deferred-length CHARACTER section-copyback discrepancies are retained with control cases and are not counted as execution agreement. A separate probe retains the existing formatted PRINT parser rejection for a literal containing only an opening square bracket; no fix is claimed in this release.

## Untouched original utility file

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `2581:35: ALLOCATABLE supports numeric and CHARACTER arrays only`. The complete original library still does not run in the interpreter. GNU Fortran compiles and runs the untouched original with -fcheck=all in its default extension mode; it exits zero at its intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects the original nonstandard ISNAN call. Original GNU logs are included in this release evidence.

## Limits and historical evidence

Earlier GNU ICE observations for CHARACTER/INDEX array edges remain documented and are not counted as agreement. Undefined-source and resource-policy cases intentionally avoid GNU execution. Original-body support, synthetic feature tests, and full-library execution are separate claims. Rank-four arrays, unsupported ALLOCATABLE shapes, unrestricted I/O, recursive ELEMENTAL and unlisted syntax/intrinsics still reject. The full M_intrinsics survey confirms 4 complete original passes, 232 explicit rejections and 13 empty files, with no regressions, mismatches, crashes or timeouts. MAX, NORM2, RESHAPE and TRANSPOSE advance past SHAPE but still reject later. Fourteen other changes are diagnostic wording only for unsupported scalar allocation; none are new whole-example passes. All three retained RESHAPE probes match GNU. The comparison is retained under this release's m-intrinsics evidence. Historical 0.28 results remain in VERIFICATION-0.28.0.md and docs/verification/0.28.0.
