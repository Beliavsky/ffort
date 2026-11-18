# Verification of prototype 0.36.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built from an empty cache without network dependencies under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity and absence of compiled files were verified. The CLI reports 0.36.0.

During that verification, one existing generator metadata entry was synchronized with its already-promoted runtime manifest case, with a separately verified isolated regeneration. Isolated regeneration reproduced all 269 fixture sources and the manifest byte for byte; all 325 sources across the audited suites were unchanged. Two stale explanatory claims were corrected. No implementation or source fixture changed, so the clean-built executable and hash remain unchanged. The followup patch and replay receipt are retained.

| Suite | Interpreter cases | Direct GNU checks | Lowered SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_character | 35/35 | 30 | 0 | 5 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatable_spec_inquiries | 37/37 | 33 | 0 | 4 |
| allocatables | 45/45 | 19 | 0 | 26 |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| bare_do | 38/38 | 38 | 0 | 0 |
| char_identifiers | 31/31 | 23 | 0 | 8 |
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
| elementary_math | 43/43 | 43 | 0 | 0 |
| explicit_dummy_bounds | 57/57 | 57 | 0 | 0 |
| findloc | 57/57 | 22 | 0 | 35 |
| forall | 85/85 | 39 | 0 | 46 |
| formatted_arrays | 47/47 | 26 | 0 | 21 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| generic_spec_guards | 15/15 | 15 | 0 | 0 |
| grouped_formats | 39/39 | 17 | 0 | 22 |
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
| nested_procedures | 54/54 | 52 | 0 | 2 |
| numeric_model_inquiries | 69/69 | 69 | 0 | 0 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| optional_arguments | 31/31 | 31 | 0 | 0 |
| optional_character | 34/34 | 34 | 0 | 0 |
| optional_colons | 29/29 | 29 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| optional_numeric_arrays | 67/67 | 41 | 0 | 26 |
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| parity_intrinsic | 34/34 | 34 | 0 | 0 |
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
| release034_integration | 16/16 | 15 | 0 | 1 |
| release035_integration | 19/19 | 19 | 0 | 0 |
| release036_integration | 32/32 | 32 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| repeat_intrinsic | 31/31 | 30 | 0 | 1 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| row_gather | 66/66 | 66 | 0 | 0 |
| saved_locals | 37/37 | 37 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| shape_intrinsic | 32/32 | 31 | 0 | 1 |
| source_limits | 10/10 | 3 | 0 | 7 |
| specification_functions | 39/39 | 39 | 0 | 0 |
| stdout_write | 39/39 | 39 | 0 | 0 |
| stdout_write_staging | 10/10 | 10 | 0 | 0 |
| target_attributes | 15/15 | 15 | 0 | 0 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **5986/5986** | **5251** | **83** | **652** |

Zero failures. Counts are logical source cases, not process invocations. Direct GNU checks include execution comparisons, compile-only assertions and required source rejections. GNU execution alongside candidate rejection establishes a boundary, not execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies remain separately classified.

- 152 native Fortran programs, 629 Python harness self-tests, 17 CLI/resource contracts and eight partitioner checks pass. Forty additional POINTER source rejections remain outside the table.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent matrices retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases and 272 numerical values.
- All 6322 existing Fortran native/corpus/example files from exact 0.35 remain present and byte-identical. Existing expectations are promoted only where the newly supported behavior justifies it. No old source fixture is rewritten or omitted to obtain a pass.
- Vendor patches 0057–0059 replay from certified 0.35 and reproduce all 457 vendor files exactly. Patch 0059 was rebased after 0057/0058 without changing its semantic delta. The integrated core patch independently replays all 463 source/vendor files. MIT licenses, vendor sources and patch ledgers remain included. The standalone upstream FortFront suite was not run.

## Bounded elementary and model intrinsics

DIM and SIGN support matching INTEGER(4/8) or REAL(4/8) arguments with scalar expansion and conformable rank-one/two/three arrays. LOG_GAMMA supports REAL(4/8), including negative noninteger arguments. Checked arithmetic avoids integer overflow and rejects gamma poles and nonfinite values. SIGN preserves tested signed-zero behavior. These names remain nonreserved and retain exact source binding.

PARITY supports default LOGICAL rank-one/two masks and the documented DIM forms, including empty-array identities. EPSILON, RADIX, TINY and HUGE use declared type/kind without evaluating operand values. Unsupported component operands reject during checking, and the structural scan memoizes at most 10,000 nodes. Metadata-only inquiry does not permit corrupted type, kind, shape, arity or slot metadata to bypass validation. Source adapter and public-IR runtime checks are independent.

The elementary suite has 43 cases, 2,960 independent native assertions and 15 producer checks. PARITY has 34 source cases and independent producer/adapter/runtime tests. The model suite has 69 source cases, 224 native assertions and 13 producer checks. The seven complete unchanged M_intrinsics demos copied into these suites retain exact source/license provenance. The full separate corpus survey below decides whole-demo progress; individual expression support alone is not counted as a complete demo.

GNU 14.2.0 has a separately reproduced runtime DIM discrepancy for valid INTEGER(8) `DIM(-HUGE(0_8),HUGE(0_8))`: runtime evaluation returns 2 at -O0 through -O3, while constant folding and the candidate return the mathematically required zero. This composition case uses an independent exact expected value and a GNU compile-only assertion. It is not counted as execution agreement. Commands, outputs, hashes and source references are in `verification/0.36.0/dim-gnu-boundary/`; comparisons elsewhere remain strict.

## Read-only numeric matrix row gathering

The bounded form `matrix(indices,:)` accepts a numeric rank-two whole-array base, a rank-one INTEGER row-index expression and a full column selector. It evaluates indices once, validates all indices before copying selected values and preserves duplicates, order, negative bounds and empty shapes. Gathered values are snapshots, including parenthesized INTENT(IN) actuals passed before an allocatable INTENT(OUT) destination is deallocated. Scatter, vector columns, rank-three, CHARACTER/LOGICAL or POINTER bases, and direct masked WHERE/FORALL gather use remain excluded. SIZE/SHAPE on a gathered value is deliberately eager, documented as a boundary rather than a no-evaluation guarantee.

The focused suite has 66 contracts: 38 GNU/candidate execution agreements, 16 checking rejections and 12 runtime checks, plus 11 runner self-tests and 66 independent native checks. Nine drivers preserve the full original filter_matrix_rows, true_pos_func and set_alloc_real_matrix dependency closure, including CRLF body bytes. Driver inputs and setup are synthetic and labeled. Existing older drivers with typed empty constructors remain explicit rejections; they were not silently promoted to complete passes.

The release composition suite passes 32 cases: 20 GNU executions (including three GNU-only boundary references), ten compile-only checks and two required source rejections. Its native target passes 797 independent assertions. It combines gathering, elementary/model intrinsics, PARITY, allocatable snapshots, sections, nested host procedures, query non-evaluation, signed zero, empty results and statement-atomic failure. It includes the seven unchanged intrinsic demos and an unchanged filter closure. Strict text/Decimal comparisons and 48 adversarial harness tests preserve tiny model constants and large integers. A new hand-built native constructor baseline initially supplied forbidden cached dimensions; the fixture alone was corrected to the existing public-IR contract before the clean aggregate. No source validator or assertion was weakened.

## Untouched full utility file and retained limits

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `9329:55: Total array element limit exceeded (131072)`. The fixed local xbig(nmax) in read_vec_data_unit declares nmax=10**8, above the unchanged 131,072-element cap. This is an intentional resource boundary, not permission to allocate 100 million elements. External-unit READ/CLOSE remain unsupported.

The file is not reduced, rewritten or given a special larger cap. Declaration analysis can precede executable-body analysis, so reaching this location does not prove all earlier routines work. Full original utilities execution remains unsupported. Exact earlier wrappers, including quick_sort, assert_le, positions_char_string, specification/SAVE helpers, fold_bounds, str_int and variable_names, remain rerun with their provenance and synthetic dependencies labeled.

GNU compiles/runs the unchanged original with -fcheck=all in its default extension mode and exits zero at its intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects its nonstandard ISNAN extension. Original GNU logs are retained; random-valued output is not compared byte for byte.

## Historical failures and scope

Version 0.34's initial list-output regression was corrected before release; the unchanged 4,096-REAL(8) smoke and ten exact/over-limit staging checks rerun here. List-directed staging remains bounded at 16 MiB with checked geometric growth; formatted staging remains 65,536 bytes. Prior completed records survive a later failed statement; statement atomicity is not whole-program rollback.

Optional stronger-profile failures are not hidden by the official debug pass. Historical 0.31 evidence records recursive-entry guard failures. The 0.34 feature-tree command `fpm test --profile release --flag '-fcheck=all -fbacktrace -ffpe-trap=invalid,zero,overflow'` failed eight native targets (six recursive-entry guards, two SIGFPE); its mean sweep passed 168/172 with four resolve_literal guard failures. No matched baseline was run for those exact flags, so they were not classified as new regressions. Logs remain in docs/verification/0.34.0/optional-strong-profile. That optional profile was not rerun for 0.36 and is not counted as passing. Official debug tests and GNU source-oracle flags are distinct.

Undefined-source/resource-policy cases deliberately skip GNU execution. Existing CHARACTER/INDEX GNU ICE observations remain documented. General file I/O, broader vector subscripts, unsupported captures/specification calls, saved arrays, rank-four arrays, unlisted pointer forms and recursive ELEMENTAL remain outside the subset. Windows and the standalone upstream FortFront suite were not run.

## Unchanged M_intrinsics survey

The pinned corpus contains 249 files: 16 complete original passes, 220 explicit rejections and 13 empty files. Against final 0.35 there are 7 new complete passes and 0 pass regressions. The comparison records 7 changed first outcomes, separately identifying complete passes and remaining diagnostic boundaries. All three retained RESHAPE probes match GNU. TINY has four different exponent spellings with exactly equal Decimal values; raw outputs and zero-tolerance equality checks are retained. The survey comparator retains signed-zero, integer/text and byte-exact CHARACTER distinctions, with 12 adversarial checks. Before/after executable identity, exact source hashes and full survey evidence are embedded. Historical verification remains in versioned reports and evidence directories.
