# Verification of prototype 0.33.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity, and absence of compiled files were verified. The CLI reports 0.33.0.

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
| explicit_dummy_bounds | 57/57 | 57 | 0 | 0 |
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
| pointer_views | 56/56 | 44 | 0 | 12 |
| procedure_identifiers | 26/26 | 16 | 0 | 10 |
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
| release032_integration | 16/16 | 16 | 0 | 0 |
| release033_integration | 14/14 | 14 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| repeat_intrinsic | 31/31 | 30 | 0 | 1 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| saved_locals | 37/37 | 37 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| shape_intrinsic | 32/32 | 31 | 0 | 1 |
| source_limits | 10/10 | 3 | 0 | 7 |
| specification_functions | 39/39 | 39 | 0 | 0 |
| target_attributes | 15/15 | 15 | 0 | 0 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **5482/5482** | **4783** | **83** | **616** |

Zero failures. Counts are logical source cases, not process invocations. Direct GNU checks include execution comparisons, compile-only assertions and required compiler rejections. Compile-only is not execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies are classified separately.

- 136 native Fortran programs, 444 Python harness self-tests, 17 CLI/resource contracts and eight partitioner checks pass. Forty additional POINTER source rejections remain outside the table.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases, and 272 numerical-matrix values.
- All 5930 existing Fortran native/corpus/example files from exact 0.32 are present and byte-identical. Supported-subset changes update manifest expectations without rewriting original Fortran inputs. The composition worker's separate tests-only inventory is not this release-wide count.
- Vendor patch 0056 replays with zero fuzz against exact 0.32 and reproduces all 457 vendor files. Earlier corrections, MIT notices and patch history remain. The standalone upstream FortFront suite was not run.

## New bounded features

- PURE specification functions: 39 focused cases comprise 16 GNU executions, 12 compile-only checks and 11 required source rejections. Sixty native checks cover metadata, purity, runtime and shared-budget guards. Direct nonrecursive PURE module functions with mandatory scalar INTEGER(4/8) inputs/results can appear in bounded automatic local/result array bounds and procedure CHARACTER lengths. General/generic/internal/optional-formal and explicit-dummy specification-function calls remain outside this increment. Checking source never executes user functions.
- Initialized scalar local SAVE: 37 focused cases comprise 16 GNU executions, 12 compile-only checks and nine required source rejections. Sixty-three native checks independently validate cached initializers, state ownership, alias rules, budgets and root reset. INTEGER/REAL kinds 4/8, default LOGICAL and fixed CHARACTER state is initialized once per execute_program root and shared by repeated/recursive activations. PURE/SIMPLE and ordinary-function write restrictions remain. Unsupported arrays, uninitialized/standalone SAVE, runtime-length CHARACTER and pointer/allocatable/target forms reject.
- Contextual PROCEDURE names: 26 focused contracts cover 14 candidate/GNU executions, ten interpreter-only source rejection boundaries and two exact original-body GNU runs that deliberately remain candidate WRITE boundaries. Eleven runner self-tests require exact CHARACTER text/case, finite numeric comparisons and clean --check output. The native test checks exact dummy/producer identity, rejects forged binding, executes the baseline and preserves genuine PROCEDURE pointer declaration metadata. Vendor 0056 changes contextual declaration entities, dummy lists, USE ONLY names and MODULE PROCEDURE specific names; the lexer still recognizes the keyword and real procedure clauses retain their grammar. Program/module units named PROCEDURE and general keyword-name support remain excluded.
- Fourteen combined cases comprise seven GNU executions, four compile-only boundaries and three matching source rejections. Twenty-one harness self-tests pass. The native composition program performs 29 checks, including 24 independent adapter/runtime mutations, repeated root execution and state reset after a late budget failure. Interactions include saved recursive CHARACTER state, specification-sized automatic arrays, explicit-dummy prefix copyback through live pointer views, empty IMPURE ELEMENTAL lanes, module-state reads, exact INTEGER(8) values, and conservative recursive saved-actual alias rejection.

## Original routines and provenance

Five unchanged bodies execute together against GNU: factorial_long, choose,
few_combinations, default_logical and recursive gen. A new module wrapper supplies
kind/generic declarations; a separate synthetic driver compares combination
algorithms, repeated saved-state calls, reset and empty extents. Raw body bytes,
comments and CRLF are preserved and checked before/after every source run. The
composition ranges include terminal CRLF; the standalone specification-function
ranges omit the last CRLF for the first three functions, so their hashes differ
only by those documented range endpoints.

The 541-byte original assert_le body is also preserved exactly in two wrappers.
GNU executes both success and formatted-diagnostic/STOP branches. The candidate
passes its contextual name declarations but still rejects WRITE(*,format) at
original line 8193. These are explicit next-boundary tests, not successful
candidate executions. This isolated routine boundary must not be confused with
the different full-source declaration boundary below.

Earlier exact original wrappers, including fold_bounds/group_sizes, str_int and
variable_names, are rerun. The separate str_int comparison is additional to the
table. Original bodies, synthetic harnesses and full-library execution are distinct
claims.

## Untouched full utility file

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `8663:63: Unsupported automatic array bound: require input dummies, parameters, inquiries, COUNT masks or bounded PURE specification calls`. This is `logical :: xmask(size(xx,1))` in filter_matrix_rows, where xx is an ALLOCATABLE INTENT(INOUT) dummy. Declaration analysis reaches this boundary before all executable bodies are analyzed. It does not establish that every earlier routine works, and the full original library still does not execute.

GNU Fortran compiles/runs the untouched original with -fcheck=all in its default extension mode and exits zero at the intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects its nonstandard ISNAN extension. Original GNU logs are retained.

## Limits, survey and historical evidence

Undefined-source and resource-policy cases intentionally avoid GNU execution. Earlier CHARACTER/INDEX GNU ICE observations remain documented and are not agreement. Broader I/O, unsupported specification inquiries, saved arrays, rank-four arrays, unlisted pointer forms, recursive ELEMENTAL and other undocumented language forms remain excluded.

The optional stronger interpreter -fcheck=all batch from 0.31 exposed seven native-test failures at six missing-RECURSIVE helpers. Its exact command and logs remain under docs/verification/0.31.0; that stronger full batch was not rerun for 0.33 and is not counted as passing. Official debug native tests and GNU source-oracle flags are distinct.

The unchanged M_intrinsics corpus contains 249 files: 4 complete original passes, 232 explicit rejections and 13 empty files. There are 0 new complete passes and 0 pass regressions. The detailed comparison records 3 first-outcome changes separately from full passes, including any same-declaration diagnostic changes. MAXLOC, MAXVAL and MINLOC receive more specific errors at the same unsupported main-program SAVE array declarations; no original advances to a later blocker. All three retained RESHAPE probes match GNU. Exact survey evidence and its tested CLI hash are embedded. Historical 0.32 results remain in VERIFICATION-0.32.0.md and docs/verification/0.32.0.
