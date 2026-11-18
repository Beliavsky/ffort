# Verification of prototype 0.32.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity, and absence of compiled files were verified. The CLI reports 0.32.0.

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
| **Total** | **5366/5366** | **4677** | **83** | **606** |

Zero failures. Counts represent logical source cases, not process invocations. Direct GNU checks include execution comparisons, explicit compile-only assertions and required compiler rejections. Compile-only is not execution agreement. SIMPLE lowered to PURE is a weaker reference. Compiler discrepancies and interpreter safety policies are classified separately, not counted as GNU execution agreement.

- 132 native Fortran programs, 412 Python harness self-tests, 17 CLI/resource contracts and eight partitioner self-checks pass.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent models retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases, and 272 numerical-matrix values.
- All 5793 existing Fortran native/corpus/example files from 0.31 are present; 5793 preserve exact bytes. All prior native, corpus and example Fortran bytes are unchanged. Newly supported or earlier-rejected cases change only manifest expectations. See source-preservation.json.
- Vendor patch 0055 replays with zero fuzz against the exact 0.31 vendor tree and reproduces all 457 vendor files byte for byte. Earlier corrections remain unchanged unless explicitly documented in the new patch ledger. MIT notices and earlier patch history remain. The standalone upstream FortFront suite was not run.

## New bounded features and source provenance

- Bounded POINTER views: 56 focused cases, 44 direct GNU checks and 12 explicit safety-policy skips. An additional 40 source rejections test the unsupported boundary. Native programs independently verify 12 metadata mutations, 26 procedure-use/context mutations, 177 direct-runtime mutations and view/lifetime scenarios. Rank-one INTEGER/REAL pointers alias fixed rank-one/two TARGET backing with shared definition flags, frozen section maps and frame-generation guards. Eligible whole TARGET actuals can be borrowed through assumed-shape TARGET dummies and returned via POINTER OUT descriptors. Procedure pointer use remains descriptor-only; general pointer values, allocatable targets, allocation/remapping and other excluded forms are rejected.
- Runtime explicit-shape dummies: 57 focused cases, with 31 GNU executions, 21 compile-only checks and five required GNU compiler rejections; 14 runner self-tests, 46 native adapter/runtime corruptions and eight producer cases. Mandatory intrinsic rank-one/two/three dummies use bounded scalar INTEGER input/INOUT bounds frozen after scalar association. Same-rank prefix element-sequence association supports rebasing, reshape, sections and expression inputs while preserving larger actual tails and definition flags. OPTIONAL/assumed-size/cross-rank and unsupported specification forms remain excluded.
- Vendor 0055 preserves literal/default CHARACTER declaration lengths and resolves actual designator lengths from their own declarations. Nonliteral lengths remain unresolved rather than fabricated as zero. Five unchanged known-length mismatch fixtures now reject at check time; exact array-element-length policy remains enforced independently at runtime.
- Sixteen combined source cases pass: ten literal expected-output GNU executions, three candidate runtime guards and three standard-valid bounded exclusions. GNU compiles but does not execute the six safety/boundary cases. Sixteen harness self-tests pass. The native composition program checks 32 adapter/runtime corruption rejections, repeated execution and an undefined-tail preservation guard.

The unchanged original fold_bounds (462 bytes) and recursive group_sizes (584
bytes) bodies retain CRLF endings and match GNU in a provenance-checked wrapper.
The get_data-style view export fixture is synthetic: it verifies the bounded
signature/association behavior, not the original error branch containing external
WRITE and implied DO. Complete original get_data execution is not claimed.
Earlier exact str_int and variable_names wrappers are rerun; the separate str_int
comparison remains additional to the source-case table.

The combined test run caught deferred-shape POINTER dummies incorrectly entering
the new explicit-bound freezing pass. They are now excluded from that pass while
retaining independent pointer descriptor validation; source/native composition
regressions cover both OPTIONAL and nonoptional forms. The first clean full run also
identified one remaining stale CHARACTER mismatch stage expectation. Its source
was retained, the expected stage was corrected from runtime to source checking,
and the complete verifier was rerun from a fresh cache. The initial failure log
is retained as expectation-correction evidence. Source merge replay,
independent review and clean full regression verify the composed implementation.

## Untouched original utility file

The 338,883-byte original retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `7967:40: Unsupported automatic array bound: require input dummies, parameters, array inquiries or supported COUNT masks`. The complete original library still does not run in the interpreter. GNU Fortran compiles and runs the untouched original with -fcheck=all in its default extension mode; it exits zero at its intentional final STOP after check_all_equal reports unequal values. Strict Fortran 2018 rejects the original nonstandard ISNAN call. Original GNU logs are included in this release evidence.

## Limits and historical evidence

Earlier GNU ICE observations for CHARACTER/INDEX array edges remain documented and are not counted as agreement. Undefined-source and resource-policy cases intentionally avoid GNU execution. Original-body support, synthetic feature tests, and full-library execution are separate claims. Rank-four arrays, unsupported ALLOCATABLE shapes, unrestricted I/O, recursive ELEMENTAL and unlisted syntax/intrinsics still reject. An optional stronger interpreter build with -fcheck=all exposed seven existing native-test failures at six missing-RECURSIVE helpers; that diagnostic run is not counted as passing. That historical isolated diagnostic run, exact command and logs remain under docs/verification/0.31.0; the stronger full batch was not rerun for 0.32. Official debug native tests and GNU source oracles use distinct build flags. The full M_intrinsics survey confirms 4 complete original passes, 232 explicit rejections and 13 empty files, with no regressions, mismatches, crashes or timeouts. ASSOCIATED advances from its POINTER declaration/association to unsupported two-argument ASSOCIATED. SIZE changes its diagnostic inside the same unsupported assumed-size declaration, not to a later program statement. Neither is a new complete pass. All three retained RESHAPE probes match GNU. The comparison is retained under this release's m-intrinsics evidence. Historical 0.31 results remain in VERIFICATION-0.31.0.md and docs/verification/0.31.0.
