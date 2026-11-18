# Verification of prototype 0.38.0

Recorded 15 November 2026 on Linux x86-64 with GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows was not executed.

## Fresh archive and full regression

A source ZIP was extracted into a fresh directory with spaces in its path. With no build cache or network dependency, `python3 scripts/verify.py` rebuilt and passed the complete native, CLI, source and harness suite under the default 8 MiB stack limit. Final implementation, vendor source, source tests, examples, configuration and verifier match the tested extraction byte for byte. Reports and manifest were assembled afterward. Archive CRC, manifest, tested-source identity and absence of compiled files were independently checked.

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
| associated_target | 51/51 | 51 | 0 | 0 |
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
| cshift | 90/90 | 90 | 0 | 0 |
| defined_operators | 19/19 | 19 | 0 | 0 |
| defined_operators/optional_operands | 6/6 | 6 | 0 | 0 |
| derived_date_independent | 73/73 | 73 | 0 | 0 |
| derived_select_integration | 18/18 | 18 | 0 | 0 |
| derived_types | 43/43 | 38 | 0 | 5 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
| elementary_math | 43/43 | 43 | 0 | 0 |
| erfc_scaled | 35/35 | 35 | 0 | 0 |
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
| isnan_intrinsic | 45/45 | 45 | 0 | 0 |
| iso_env_aliases | 33/33 | 33 | 0 | 0 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| literal_substrings | 48/48 | 27 | 0 | 21 |
| location_intrinsics | 58/58 | 55 | 0 | 3 |
| logical_allocatables | 21/21 | 16 | 0 | 5 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| logical_intrinsics | 41/41 | 35 | 0 | 6 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| model_decomposition | 45/45 | 45 | 0 | 0 |
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
| random_functions | 40/40 | 39 | 0 | 1 |
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
| release037_integration | 37/37 | 37 | 0 | 0 |
| release038_integration | 26/26 | 26 | 0 | 0 |
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
| spacing_nearest | 47/47 | 47 | 0 | 0 |
| specification_functions | 39/39 | 39 | 0 | 0 |
| stdout_write | 39/39 | 39 | 0 | 0 |
| stdout_write_staging | 10/10 | 10 | 0 | 0 |
| target_attributes | 15/15 | 15 | 0 | 0 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| where | 60/60 | 26 | 0 | 34 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **6435/6435** | **5699** | **83** | **653** |

Zero failures. These are logical source cases, not invocation counts. Direct GNU checks combine execution comparisons, compile-only assertions and required source rejections; compile-only is not execution agreement. SIMPLE lowered to PURE is a weaker reference. Policy and compiler-discrepancy cases remain separately classified.

- All 169 native Fortran programs and 799 harness self-tests pass, plus 17 CLI/resource contracts, eight partitioner checks and 39 additional POINTER source rejections and one promoted ASSOCIATED runtime safety probe outside the table.
- Eight metadata CLI checks include a GNU utility-scale comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Retained matrices cover 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases and 272 numerical values.
- All 6743 prior Fortran files remain present. All 6583 source-program fixtures under tests/examples are byte-identical. Of 160 existing native test sources, one has exactly two disclosed assertion updates: ASSOCIATED invalid arity changes from two to three arguments, and the nonpointer-first error substring tracks the current diagnostic. Both rejection checks remain; all other native files are byte-identical. Source hashes and exact allowed changes are recorded separately from manifest expectation promotions.
- Cumulative vendor replay reproduces all 457 vendor files. The canonical integrated core patch independently replays the final implementation/vendor sources. Original MIT licenses and patch ledgers remain included. The standalone upstream FortFront test suite was not run.

## Intrinsic imports and processor model

ISO_FORTRAN_ENV ONLY lists support local aliases of REAL32, REAL64, INT32 and INT64, preserving exact remote identity rather than inferring it from equal integer values. REAL128=-1 explicitly reports that this interpreter does not support a 128-bit REAL kind. It does not enable REAL(16) declarations or operations. Intrinsic procedure-level imports and retained continuation trivia are validated independently; ordinary module renaming and unsupported intrinsic entities remain bounded rejections.

The complete unchanged COSH, TAN, TANH and EPSILON examples are retained with source hashes and license. Supported import spellings do not imply that every program importing an unsupported entity or using other unsupported features now executes. See [ISO aliases](ISO-FORTRAN-ENV-ALIASES.md).

## ERFC_SCALED and independent accuracy

The elemental REAL(4/8) implementation preserves input kind and supported scalar/array shapes. A stable large-positive asymptotic tail retains representable subnormal results; guarded split-exponent reflection handles the negative finite boundary. The finite-value policy is unchanged. It does not use an unguarded `exp(x*x)*erfc(x)` formula.

Separately from the source-case table, 439 exact-binary inputs pass independent 120-digit mathematical references with explicit 2 ULP (REAL4) and 4 ULP (REAL8) budgets. These are dedicated numerical accuracy thresholds, not a relaxed generic source comparator.
- REAL(4): 215 points; maximum observed candidate error 0.499934 ULP; 5 separately recorded GNU endpoint discrepancies, 0 unexpected discrepancies.
- REAL(8): 224 points; maximum observed candidate error 2.142 ULP; 6 separately recorded GNU endpoint discrepancies, 0 unexpected discrepancies.

GNU 14 runtime can return zero for representable positive subnormals or Infinity before the mathematical negative-tail overflow boundary. Those results are preserved alongside the independent references and are not called execution agreement. The complete unchanged demo_erfc_scaled is a separate ordinary GNU comparison. See [ERFC_SCALED](ERFC-SCALED.md) and the retained reference generator/receipt.

## ASSOCIATED and CSHIFT

Two-argument ASSOCIATED compares the supported pointer/target element mapping with lifetime and descriptor checks, without reading pointee values. Merely sharing a backing owner is insufficient. Empty, reversed, singleton, undefined and absent-optional cases are distinguished; documented GNU discrepancies remain separate from ordinary supplied-target differential checks. Existing pointer allocation, target and storage restrictions remain in force. For the three absent nonpointer OPTIONAL TARGET cases, GNU 14.2 returns false where the separately cited standard semantics require true/false/true; these are specification-only candidate checks with GNU compilation, not claimed execution agreement.

CSHIFT supports the documented rank-one and rank-two cases with scalar or conformable rank-minus-one SHIFT and default/explicit DIM. INTEGER(4/8) shifts are reduced without negating their minimum value. Element kinds, fixed CHARACTER lengths, empty shapes, source-name shadowing, snapshot behavior and resource limits are independently checked. A rank-one-only subset would not suffice for the unchanged complete rank-two demonstration; that demonstration is retained and verified. A separate GNU 14 empty-rank-two materialization failure is retained as a compile-only reference with independent candidate invariants. The CSHIFT comparator requires exact decimal numeric equality, distinguishes signed zero and rejects tolerance overrides.

Detailed contracts and independent native mutation evidence are included with each feature. No unsupported higher-rank transformation, pointer lifetime, nonfinite domain or unlisted I/O feature is silently enabled.

## Cross-feature and historical verification

The release038_integration suite combines imports, inquiries, pointer identity, shifts and scaled-error-function values with pinned original programs and independent expectations. All 26 source cases, 42 comparator/harness checks and 429 native assertions pass; source results and native evidence are retained in the final receipt, with focused intermediate results labeled separately. Initial new-test scaffolding and public shape-API expectation corrections are preserved as failed intermediate evidence, not hidden or counted as passes. All prior original-body wrappers and staged GNU checks are rerun, including the RNG utilities, helper-free finite quick_sort, filter_matrix_rows, assert_le, fold_bounds, str_int and specification/SAVE helpers. Synthetic scaffolding and adapted-only evidence remain labeled.

Historical GNU limitations remain visible, including DIM and SET_EXPONENT edge discrepancies and CHARACTER compiler defects. The optional 0.34 feature-tree command `fpm test --profile release --flag '-fcheck=all -fbacktrace -ffpe-trap=invalid,zero,overflow'` failed eight native targets (six recursive-entry guards and two SIGFPE cases); its mean sweep passed 168/172 with four resolve_literal guard failures. No matched baseline existed for those exact extra flags. Those observations are not reclassified as new regressions, and that optional profile was not rerun or counted as passing in 0.38. Evidence remains under docs/verification/0.34.0/optional-strong-profile. Windows and the standalone upstream FortFront suite were not executed.

## Untouched full utility source

The original source is 338,883 bytes, SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both check and execution reject with zero stdout at `9329:55: Total array element limit exceeded (131072)`. The fixed xbig(nmax) declaration uses nmax=10**8, above the unchanged 131,072-element cap. No original rewrite or enlarged cap bypasses that boundary. Declaration analysis precedes some body analysis, so the first diagnostic does not prove all earlier routines execute. External READ/CLOSE remain unsupported.

GNU compiles/runs the unchanged original with -fcheck=all in default extension mode, exiting zero at its intentional final STOP after check_all_equal reports unequal values. Random-valued output is not compared byte for byte. Strict standard mode rejects its nonstandard ISNAN extension. Full original-library execution by this interpreter is not claimed.

## Complete unchanged M_intrinsics survey

All 249 pinned files retain their certified 0.37 hashes. Results: 27 complete original passes, 209 explicit rejections and 13 empty placeholders. There are 7 new complete passes, 0 regressions and 81 changed first outcomes. Detailed transitions separate full successes from changed blockers or wording. The retained comparison classifies 37 later blockers, 28 wording-only changes, 6 changes within the same unsupported statement and 3 diagnostic-priority/specificity changes. All three retained probes match GNU; before/after executable identity is verified.

Exact Decimal exponent-notation comparisons preserve numerical value without tolerance; signed-zero/integer/text and significant CHARACTER distinctions remain. The complete raw m-intrinsics-0.38-verification.zip is included with compact reports under docs/verification/0.38.0/m-intrinsics, including pinned sources, raw outputs, GNU evidence and scripts, without compiled executables.
