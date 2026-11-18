# Verification of prototype 0.31.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity, and absence of compiled files were verified. The CLI reports 0.31.0.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_character | 35/35 | 30 | 0 | 5 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatables | 45/45 | 19 | 0 | 26 |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| bare_do | 38/38 | 38 | 0 | 0 |
| character_arrays | 49/49 | 48 | 0 | 1 |
| character_intrinsics | 37/37 | 36 | 0 | 1 |
| character_len_elements | 19/19 | 19 | 0 | 0 |
| character_parameters | 58/58 | 57 | 0 | 1 |
| character_procedures | 35/35 | 35 | 0 | 0 |
| character_search | 58/58 | 58 | 0 | 0 |
| character_substrings | 35/35 | 34 | 0 | 1 |
| class_type_bound | 44/44 | 40 | 0 | 4 |
| control_flow | 57/57 | 26 | 0 | 31 |
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
| findloc | 57/57 | 22 | 0 | 35 |
| forall | 85/85 | 39 | 0 | 46 |
| formatted_arrays | 47/47 | 25 | 0 | 22 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| hyperbolic_intrinsics | 32/32 | 32 | 0 | 0 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| intent_spelling | 31/31 | 29 | 0 | 2 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| literal_substrings | 48/48 | 27 | 0 | 21 |
| location_intrinsics | 58/58 | 55 | 0 | 3 |
| logical_allocatables | 21/21 | 16 | 0 | 5 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| logical_intrinsics | 41/41 | 35 | 0 | 6 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| module_use | 26/26 | 26 | 0 | 0 |
| mutable_modules | 42/42 | 33 | 0 | 9 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| optional_arguments | 31/31 | 31 | 0 | 0 |
| optional_character | 34/34 | 34 | 0 | 0 |
| optional_colons | 29/29 | 29 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| optional_numeric_arrays | 67/67 | 41 | 0 | 26 |
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| quoted_operators | 21/21 | 13 | 0 | 8 |
| rank_three | 50/50 | 45 | 0 | 5 |
| rank_three_allocatables | 25/25 | 21 | 0 | 4 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| recursion | 31/31 | 17 | 0 | 14 |
| release025_integration | 3/3 | 3 | 0 | 0 |
| release026_integration | 6/6 | 6 | 0 | 0 |
| release027_integration | 10/10 | 10 | 0 | 0 |
| release028_integration | 7/7 | 7 | 0 | 0 |
| release029_integration | 12/12 | 11 | 0 | 1 |
| release030_integration | 12/12 | 11 | 0 | 1 |
| release031_integration | 14/14 | 12 | 0 | 2 |
| release_integration | 10/10 | 10 | 0 | 0 |
| repeat_intrinsic | 31/31 | 30 | 0 | 1 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| shape_intrinsic | 32/32 | 31 | 0 | 1 |
| source_limits | 10/10 | 3 | 0 | 7 |
| target_attributes | 15/15 | 15 | 0 | 0 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **5237/5237** | **4560** | **83** | **594** |

Zero failures. Counts represent logical source cases, not process invocations. Direct GNU checks include execution comparisons, explicit compile-only assertions and required compiler rejections. Compile-only is not execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies are classified separately, not counted as GNU execution agreement.

- 126 native Fortran programs, 369 Python harness self-tests, 17 CLI/resource contracts and eight partitioner self-checks pass.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases, and 272 numerical-matrix values.
- All 5617 existing Fortran native/corpus/example files from 0.30 are present; 5616 preserve exact bytes. The sole native fixture repair sets the hand-built OP_NEXT cached symbol to match OP_DO, retaining all 53 runtime assertions. Existing corpus/example Fortran source bytes remain unchanged; newly admitted source changes only its expectation. The preservation report identifies the precise native file change. See source-preservation.json.
- New vendor patches replay with zero fuzz against the exact 0.30 vendor tree and reproduce all 457 vendor files byte for byte. Earlier corrections remain unchanged unless explicitly documented in the new patch ledger. MIT notices and earlier patch history remain. The standalone upstream FortFront suite was not run.

## New bounded features and source provenance

- TARGET declarations: 15 focused source cases with ten GNU execution comparisons, four required GNU source rejections and one compile-only POINTER boundary, plus 13 harness self-tests. Native checks reject eight forged TARGET adapter metadata variants and one impossible PARAMETER/TARGET runtime variant, and verify three repeated executions. Supported intrinsic scalar and rank-one/two/three local/module/dummy declarations preserve TARGET explicitly, including bounded ALLOCATABLE and OPTIONAL combinations. Existing value-result argument and writable-alias rules are unchanged. This does not implement pointers, association or escaping aliases; original get_data remains unsupported.

- Scalar REPEAT: 31 synthetic cases, with ten GNU executions, ten compile-only checks, ten compiler rejections and one deliberately skipped enormous constant allocation. The independent matrix checks 75 exact-blank results; 882 direct IR assertions and eight producer cases verify metadata, inquiry evaluation and nonreserved name binding. Counts must be nonnegative and results stay within the existing 65,536-character limit.
- Literal CHARACTER substring reads preserve decoded literal bytes, scalar INTEGER bounds and source structure. The focused suite separates valid strict GNU executions from source rejections and runtime-policy probes. Native tests cover 176 independent adapter/runtime checks and six producer structures. Literal bases are read-only; broader expression bases, stride syntax, nondefault kinds and the documented quoted-bracket/declaration-length boundaries remain excluded.
- Bare DO: 38 focused cases, with 19 GNU executions, nine compile-only infinite/resource-bound cases and ten required GNU source rejections, plus 41 native corruption/cleanup/budget checks. Named EXIT/CYCLE and nested counted/bare loops preserve control identity and share the existing work budget. DO WHILE, labeled termination and DO CONCURRENT remain unsupported.
- Quoted operator spellings remain CHARACTER data: 21 focused cases comprise 13 GNU executions and eight candidate source-rejection checks, plus seven native parsing/producer/runtime cases. Actual unary and binary operators retain their precedence. The existing quoted-bracket and quoted-parenthesis boundaries remain explicit rejections.
- Cross-feature integration covers TARGET/LOGICAL descriptors, SHAPE/FINDLOC, optional forwarding, CHARACTER lengths, section copyback, recursion, REPEAT/literal composition and exact original wrappers. Its native program checks 34 metadata rejections plus valid repeated execution. GNU executions, compiler-only boundaries and runtime safety probes remain separately counted.

The unchanged original str_int body retains all CRLF bytes and matches ten
explicit formatted outputs under GNU and the candidate. The separate original
comparison is additional to the synthetic source-case table. The original
variable_names body also executes within the combined suite, retaining its
str_int and default_integer dependency bodies. Minimal modules/drivers are
synthetic and clearly identified; no original body or loop is rewritten.

## Untouched original utility file

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `6326:16: Unsupported declaration attribute`. The complete original library still does not run in the interpreter. GNU Fortran compiles and runs the untouched original with -fcheck=all in its default extension mode; it exits zero at its intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects the original nonstandard ISNAN call. Original GNU logs are included in this release evidence.

## Limits and historical evidence

Earlier GNU ICE observations for CHARACTER/INDEX array edges remain documented and are not counted as agreement. Undefined-source and resource-policy cases intentionally avoid GNU execution. Original-body support, synthetic feature tests, and full-library execution are separate claims. Rank-four arrays, unsupported ALLOCATABLE shapes, unrestricted I/O, recursive ELEMENTAL and unlisted syntax/intrinsics still reject. An optional stronger interpreter build with -fcheck=all exposed seven existing native-test failures at six missing-RECURSIVE helpers; that diagnostic run is not counted as passing. Its exact command, failure names and logs are retained in strong-check-followup.md and associated evidence. Official debug native tests and GNU source oracles use distinct build flags. The full M_intrinsics survey confirms 4 complete original passes, 232 explicit rejections and 13 empty files, with no regressions, mismatches, crashes or timeouts. The detailed comparison distinguishes later first diagnostics and wording-only changes from whole-example passes. All three retained RESHAPE probes match GNU. The comparison is retained under this release's m-intrinsics evidence. Historical 0.30 results remain in VERIFICATION-0.30.0.md and docs/verification/0.30.0.
