# Verification of prototype 0.34.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity and absence of compiled files were verified. The CLI reports 0.34.0.

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
| **Total** | **5669/5669** | **4936** | **83** | **650** |

Zero failures. Counts are logical source cases, not process invocations. Direct GNU checks include execution comparisons, compile-only assertions and required compiler rejections. A successful GNU run alongside a candidate rejection establishes a boundary, not interpreter execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies are classified separately.

- 142 native Fortran programs, 523 Python harness self-tests, 17 CLI/resource contracts and eight partitioner checks pass. Forty additional POINTER source rejections remain outside the table.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases and 272 numerical-matrix values.
- Of 6051 existing Fortran native/corpus/example files from exact 0.33, 6049 remain byte-identical. All corpus/example inputs are unchanged. Exactly two native test lines adapt to newly supported format groups: `(2(a))` becomes accepted, and the existing grammar-rejection probe uses `(2(i3,/))` to retain its unsupported slash. No assertion was removed. Exact differences are recorded in source-preservation.json. Other promotions change manifests/generators, not Fortran inputs. The composition worker's separate inventory is not this release-wide count.
- No new vendor delta: all 457 vendor files match exact 0.33, retaining corrections through 0056, MIT notices and patch history. The standalone upstream FortFront suite was not run. The canonical integrated core patch independently replays against 0.33 and reproduces all 463 source/vendor files.

## New bounded features

- Default stdout WRITE: 39 cases include 19 safe GNU executions, 18 compile-only boundary/runtime checks and two required GNU rejections. Nineteen runner self-tests protect exact staged output and status handling. Ten additional staging cases cover PRINT and WRITE with 4,096/65,536 REAL(8) values, exact 16 MiB records, one-byte-over rejection and preservation of prior records; six execute against GNU and four are compile-only. List-directed output uses a separately bounded 16 MiB geometric-capacity buffer, while formatted/grouped output retains its 65,536-byte cap. Positional WRITE(*,*) and WRITE(*,literal_format) reuse existing PRINT evaluation and rendering, including registered derived output; empty item lists are supported. No numeric/variable unit, keyword controls, files or interactive input are added. Existing purity, recursive-I/O and statement-atomic output protections remain. A failed later statement preserves previously completed records but emits no partial record of its own.
- Nested literal format groups: 39 focused cases include 17 GNU execution comparisons. The remaining malformed/resource/no-data cases are interpreter contract probes without GNU execution. Groups work with PRINT, stdout WRITE, scalar internal WRITE and existing defined-output child WRITE. Reversion resumes at the last closed outer-level group, including its repeat. Existing descriptor letters, internal single-record restrictions and bounded traversal remain. Native tests validate instruction metadata, producer default-unit shapes and format programs. See GROUPED-FORMATS.md for exact repeat, node and byte caps.
- ALLOCATABLE dummy specification inquiries: 37 cases include 33 GNU checks and four intentionally skipped unallocated-input safety probes; 356 native checks and 15 harness self-tests pass. SIZE and scalar-DIM LBOUND/UBOUND of mandatory rank-one/two/three ALLOCATABLE IN/INOUT dummies may size supported automatic locals and CHARACTER lengths. Descriptor association and allocation validation precede freezing the entry shape; later reallocation does not resize locals. Undefined elements do not prevent descriptor inquiry. OPTIONAL, OUT and pointer specification inquiries remain excluded.
- Contextual CHAR: 31 cases include 21 shared candidate/GNU executions, two GNU-only data-rename boundaries and eight candidate rejection contracts; 29 native identity/mutation checks and 11 harness self-tests pass. Declared variables, arrays, dummies and procedures take precedence over intrinsic lookup, while unshadowed CHAR still works. Independent source-binding checks reject forged user-function/generic calls represented as intrinsic CHAR. There is no global keyword or lexer reclassification.
- Generic specification-call safety: composition exposed an unresolved generic-specific index dereference. The parser now validates generic ID, specific procedure index and dummy-list availability before accessing them. Unsupported generic specification calls reject with a source diagnostic in both check/run modes, without a host crash. Fifteen cases cover nine GNU-valid candidate boundaries, five shared ordinary-generic/direct-specific successes and one explicitly classified GNU CHAR/LEN compile rejection. Two runner self-tests pass. This does not add generic specification-function semantics or execute user functions during checking.
- Sixteen combined cases comprise seven shared successful executions, two GNU-only boundaries, three compile-only checks, three required source rejections and one unallocated-input GNU skip. Thirty-two runner self-tests and 76 native composition checks pass. Interactions cover saved state/root reset, direct PURE CHAR specification functions, frozen descriptor shapes through reallocation, exact INTEGER(8) values, grouped internal/stdout output, pointer/explicit-dummy composition and atomic output after late errors. Independent metadata mutations and the original generic crash remain regressions.

## Regression caught before packaging

The first empty-cache aggregate detected one real regression: the new list-directed 65,536-byte staging cap rejected the unchanged 4,096-REAL(8) random-distribution PRINT test. All other preliminary suites passed. The correction separates the list-directed cap from formatted output and uses checked geometric growth rather than repeated full-record concatenation. The original input was not modified. Preliminary failed logs are retained under preliminary-staging-regression; they are superseded by the complete fresh corrected aggregate above. The failed preliminary run is not counted as a passing release verification.

## Original routines and provenance

Four byte-preserved original bodies execute together against GNU: positions_char_string, true_pos_func, set_alloc_int_vec and assert_le. The source bytes, comments and CRLF are retained. Module/generic wrappers and reporting drivers are synthetic and labeled. Both assertion success and formatted-diagnostic/STOP branches execute, with exact output and the interpreter's documented bare-STOP notice checked separately from GNU stderr. The original assert_le body retains all 541 bytes; no internal WRITE or source rewriting substitutes for its external WRITE.

The complete original filter_matrix_rows body plus original true_pos_func and set_alloc_real_matrix dependencies executes under GNU across filtering, all/none retained rows, invalid columns and empty input. The candidate still rejects `xx(true_pos(xmask),:)` because vector subscripts are outside the subset. This is not counted as candidate success. The standalone inquiry suite separately preserves original fragments with a continued single-line IF producer-location boundary, and an explicitly adapted block-IF helper that omits I/O and final gather. Original, adapted and synthetic evidence are not interchangeable.

Earlier exact original wrappers, including factorial_long/choose/few_combinations/default_logical/gen, fold_bounds/group_sizes, str_int and variable_names, are rerun. The separate str_int comparison is additional to the table. These wrappers do not establish full-library execution.

## Untouched full utility file

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `8926:16: END procedure name does not match`. This is `end subroutine quick_sort_1` within recursive quick_sort, which contains nested procedures with host association. The source is GNU-valid; the end-name message reflects the prototype's unsupported nested-procedure structure, not an original spelling error. Declaration analysis can precede executable-body checking, so reaching this point does not prove that every earlier routine works. Full original utilities execution remains unsupported.

GNU Fortran compiles/runs the untouched original with -fcheck=all in its default extension mode and exits zero at the intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects its nonstandard ISNAN extension. Original GNU logs are retained.

## Limits, survey and historical evidence

Undefined-source and resource-policy cases intentionally avoid GNU execution. Earlier CHARACTER/INDEX GNU ICE observations remain documented and are not agreement. General file I/O, vector subscripts, nested procedure host association, unsupported specification inquiries/functions, saved arrays, rank-four arrays, unlisted pointer forms and recursive ELEMENTAL remain excluded.

The optional stronger interpreter -fcheck=all batch from 0.31 exposed seven native-test failures at six missing-RECURSIVE helpers. Its command and logs remain under docs/verification/0.31.0; that exact older batch was not rerun for 0.34 and is not counted as passing. A separate optional feature-tree run used `fpm test --profile release --flag '-fcheck=all -fbacktrace -ffpe-trap=invalid,zero,overflow'` and exited 2: six tests encountered nonrecursive-entry guards and two received SIGFPE. No matched baseline was run under those exact flags, so these are neither passing checks nor classified new regressions. The exact eight-test list and log are retained under optional-strong-profile; four focused output-native targets passed under those flags. Its broader mean suite passed 168/172, including the unchanged random-distribution smoke; four source checks encountered the vendor resolve_literal nonrecursive guard. Those separate logs are also retained. Official clean debug tests and GNU source-oracle flags are distinct.

The unchanged M_intrinsics corpus contains 249 files: 9 complete original passes, 227 explicit rejections and 13 empty files. There are 5 new complete passes and 0 pass regressions. The detailed comparison records 27 first-outcome changes separately from complete passes, including any same-declaration diagnostic changes. Five original demos newly pass: ADJUSTR, INDEX, REPEAT, RETURN and SCAN. ADJUSTR and REPEAT additionally pass byte-exact output comparison, preserving significant padding. Twenty-two other originals change rejection diagnostics: ten remain bounded output-statement restrictions and twelve reach expression/procedure boundaries; none are counted as full passes. All three retained RESHAPE probes match GNU. Exact survey evidence, before/after executable identity and tested CLI hash are embedded. Historical 0.33 results remain in VERIFICATION-0.33.0.md and docs/verification/0.33.0.
