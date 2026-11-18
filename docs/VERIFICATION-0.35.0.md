# Verification of prototype 0.35.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity and absence of compiled files were verified. The CLI reports 0.35.0.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
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
| release034_integration | 16/16 | 15 | 0 | 1 |
| release035_integration | 19/19 | 19 | 0 | 0 |
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
| stdout_write | 39/39 | 39 | 0 | 0 |
| stdout_write_staging | 10/10 | 10 | 0 | 0 |
| target_attributes | 15/15 | 15 | 0 | 0 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **5742/5742** | **5007** | **83** | **652** |

Zero failures. Counts are logical source cases, not process invocations. Direct GNU checks include execution comparisons, compile-only assertions and required source rejections. A GNU execution alongside candidate rejection establishes a boundary, not interpreter execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies remain separately classified.

- 144 native Fortran programs, 564 Python harness self-tests, 17 CLI/resource contracts and eight partitioner checks pass. Forty additional POINTER source rejections remain outside the table.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases and 272 numerical-matrix values.
- All 6246 existing Fortran native/corpus/example files from exact 0.34 remain present and byte-identical. No old fixture is rewritten or omitted to obtain the new results.
- No vendor delta: all 457 vendor files match exact 0.34, retaining patches through 0056 and MIT notices. The canonical integrated core patch independently replays and reproduces all 463 source/vendor files. The standalone upstream FortFront suite was not run.

## Bounded internal procedures

Non-ELEMENTAL module functions/subroutines may contain one level of internal functions/subroutines. Calls bind to the exact live defining-host activation. Supported captures include ordinary intrinsic scalars/arrays, parameters and bounded initialized SAVE state. Recursive host activations remain separate; suspended children and sibling calls retain the correct host. Internal names stay local to their host, may shadow module procedures, and cannot escape as closures or procedure arguments.

Captured mandatory scalar INTEGER host IN/INOUT dummies can participate in existing bounded child array/CHARACTER specification expressions. Other capture and specification restrictions remain explicit. Host OPTIONAL, POINTER, TARGET, ALLOCATABLE, runtime-length CHARACTER, derived/polymorphic and function-result captures are excluded. Uncaptured objects of those kinds may coexist. Deeper nested CONTAINS, ELEMENTAL hosts and mutable main-program host association remain unsupported.

Purity, SIMPLE, ordinary-function side effects, active DO variables, definition flags, exact metadata and conservative dummy/host alias checks remain enforced. Explicitly IMPURE ELEMENTAL children retain their existing effect rules. The 64-frame, shared-work, source and array limits are unchanged. Live-frame references are cleared on return and checked failure; no process-global closure state is added.

The focused suite passes 54 cases: 25 GNU executions, 17 compile-only checks, ten required source rejections and two interpreter-policy skips. Its native test passes 116 independent metadata/state/budget checks. The new composition suite passes 19 cases: eleven GNU executions, seven compile-only boundaries/runtime probes and one required PURE source rejection. Its 41 runner self-tests cover exact text, finite numeric comparison, safe reference modes, diagnostics, provenance and record atomicity. Native composition passes 180 checks, including independent verifier/runtime mutations, recursive activation and SAVE/root-reset checks, orphan child rejection, and cleanup after budget failure. Source composition includes frozen arrays derived from an uncaptured allocatable descriptor, quoted CHAR/substrings, negative-bound sections, grouped output, large list records and exact completed-record prefixes on later failure.

## Original quick_sort and preserved routines

The complete original quick_sort body from xutilities lines 8870–8942, including quick_sort_1 and interchange_sort, retains all 2,517 bytes and 73 CRLF endings. Both the focused and composition runners verify exact source/body identity. The wrapper supplies dp and a small synthetic elemental isnan generic; that helper and the driver are explicitly not claimed as original source.

GNU comparisons cover tested finite inputs, empty/singleton arrays, interchange-sort thresholds, larger arrays, duplicates, sorted/reverse order, repeated calls and value/permutation consistency. Composition additionally applies grouped output and host-state interactions. Preserving and executing this body is not the same as executing the complete original library or proving every NaN/unsupported input path.

Earlier exact original wrappers and their provenance remain rerun, including assert_le, positions_char_string and its dependencies, factorial_long/choose/few_combinations/default_logical/gen, fold_bounds/group_sizes, str_int and variable_names. The complete original filter_matrix_rows closure remains an explicit vector-subscript boundary. No adapted helper is presented as unchanged original code.

## Untouched full utility file and retained limits

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `9329:55: Total array element limit exceeded (131072)`. The fixed local xbig(nmax) in read_vec_data_unit declares nmax=10**8, above the unchanged 131,072-element cap. This is an intentional resource boundary, not permission to allocate 100 million elements. The routine also needs external-unit READ/CLOSE, which remain unsupported.

The file is not reduced, rewritten or given a special larger cap. Declaration analysis can precede executable-body analysis, so reaching this location does not prove all earlier routines work. Full original utilities execution remains unsupported.

GNU compiles/runs the unchanged original with -fcheck=all in its default extension mode and exits zero at the intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects its nonstandard ISNAN extension. Original GNU logs are retained.

## Historical failures and scope

Version 0.34's initial list-output regression was corrected before that release; the unchanged 4,096-REAL(8) smoke and ten exact/over-limit staging checks rerun here. List-directed staging remains bounded at 16 MiB with checked geometric growth; literal-formatted staging remains 65,536 bytes. Previously completed output records are preserved when a later statement fails; statement atomicity is not whole-program rollback.

Optional stronger-profile failures are not hidden by the official debug pass. Historical 0.31 evidence records recursive-entry guard failures. The separate 0.34 feature-tree command `fpm test --profile release --flag '-fcheck=all -fbacktrace -ffpe-trap=invalid,zero,overflow'` failed eight native targets (six recursive-entry guards, two SIGFPE), and its mean sweep passed 168/172 with four resolve_literal guard failures. No matched baseline was run for those exact flags, so they were not classified as new regressions. Exact logs/lists remain under docs/verification/0.34.0/optional-strong-profile. That optional profile was not rerun for 0.35 and is not counted as passing. Official debug tests and GNU source-oracle flags are distinct.

Undefined-source/resource-policy cases deliberately skip GNU execution. Existing GNU CHARACTER/INDEX ICE observations remain documented. General file I/O, vector subscripts, unsupported captures/specification calls, saved arrays, rank-four arrays, unlisted pointer forms and recursive ELEMENTAL remain outside the subset. Windows and the standalone upstream FortFront suite were not run.

## Unchanged M_intrinsics survey

The pinned corpus contains 249 files: 9 complete original passes, 227 explicit rejections and 13 empty files. Against final 0.34 there are 0 new complete passes and 0 pass regressions. The comparison records 0 changed first outcomes, separately identifying complete passes and remaining diagnostic boundaries. All three retained RESHAPE probes match GNU. Before/after executable identity, exact source hashes and full survey evidence are embedded. Historical 0.34 verification remains in VERIFICATION-0.34.0.md and docs/verification/0.34.0.
