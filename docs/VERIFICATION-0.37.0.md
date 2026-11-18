# Verification of prototype 0.37.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

A source ZIP was extracted into a new directory whose path contains spaces. `python3 scripts/verify.py` built with no build cache or network dependency under the default 8 MiB stack limit and completed all native, CLI, source and harness suites. Final implementation, vendor source, source tests, examples, configuration and verifier match that tested extraction byte for byte. Reports and the SHA-256 manifest were assembled afterward. Archive CRC, manifest contents, tested-source identity and absence of compiled files were verified. The CLI reports 0.37.0.

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
| isnan_intrinsic | 45/45 | 45 | 0 | 0 |
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
| **Total** | **6200/6200** | **5464** | **83** | **653** |

Zero failures. Counts are logical source cases, not process invocations. Direct GNU checks include execution comparisons, compile-only assertions and required source rejections. GNU execution alongside candidate rejection establishes a boundary, not execution agreement. SIMPLE lowered to PURE is a weaker reference. Random-stream, compiler-discrepancy and safety-policy cases are separately classified.

- 160 native Fortran programs and 707 Python harness self-tests pass, together with 17 CLI/resource contracts and eight partitioner checks. Forty additional POINTER source rejections remain outside the table.
- Eight metadata CLI checks include a GNU execution comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Independent matrices retain 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases and 272 numerical values.
- All 6515 existing Fortran native/corpus/example files from exact 0.36 remain present and byte-identical. No historical source rewrite, omission or acceptance promotion is used to obtain this release's new passes.
- Vendor patches 0060, 0061 and 0062 replay from certified 0.36 and reproduce all 457 vendor files exactly. The registry grows from 82 to 89 entries. Each feature's semantic delta is retained; shared type/rank tables are additive. The canonical integrated core patch independently replays all 463 source/vendor files. MIT notices, upstream licenses and patch ledgers remain included. The standalone upstream FortFront test suite was not run.

## Ordinary-function RNG effects

Ordinary, unprefixed impure functions can use RANDOM_NUMBER with the execution-owned pseudorandom stream. Scalar and intrinsic rank-one/two/three function results and local harvests are covered. PURE/SIMPLE and transitive purity restrictions remain, as do the bans on ordinary-function external I/O and module/SAVE/captured-host writes. Function dummies remain INTENT(IN); RNG does not make them writable. Explicit non-elemental IMPURE prefixes, RANDOM_SEED/RANDOM_INIT and user-shadowed RANDOM_NUMBER remain outside this subset.

Scalar impure function occurrences are cached lazily once per statement evaluation. Distinct occurrences and loop iterations remain separate; array results retain their existing occurrence cache. KIND does not evaluate its operand. An empty array RHS suppresses its scalar operand calls, whereas assigning a scalar RHS to an empty target still evaluates that scalar. The test suite checks both choices rather than assuming a universal no-evaluation rule.

Each RANDOM_NUMBER harvest stages addresses, values and RNG state. Failure in that operation, including its destination-subscript evaluation, restores that operation's state. Earlier successful operations can remain committed: this is not whole-statement, whole-function or whole-program rollback. The existing budgets, temporary caps, frame depth, writability checks and REAL32/64 rounding remain unchanged.

The focused suite passes 40 source cases, 137 independent native checks and four harness tests. Six complete original RNG utility bodies are preserved, with source/dependency provenance and synthetic driver setup labeled. GNU validates valid range, shape and logical properties, not equality with the interpreter's different generator. Independent same-seed candidate comparisons verify direct-call versus function streams, draw counts, reset/continuation, empty behavior, inquiries, broadcast/loop occurrences and failure-state handling.

## Numeric decomposition, character code and adjacent-real intrinsics

FRACTION and SET_EXPONENT retain REAL(4/8) input kind; EXPONENT returns default INTEGER. SET_EXPONENT accepts INTEGER(4/8) exponent arguments and applies bounded underflow/overflow handling before narrowing a wide exponent. IACHAR supports length-one default CHARACTER and result INTEGER kinds 4/8. SPACING and NEAREST preserve X's REAL kind and independently validate direction operands, including mixed direction kinds. Scalar expansion, supported rank-one/two/three shapes, keywords, empty results, source-defined name shadowing and metadata-only KIND are tested.

Tests cover signed zero, REAL32 precision, subnormals, finite limits, all 128 ASCII codes, malformed metadata and unsupported domains. Nonfinite-value policy is not relaxed. Detailed boundaries are in MODEL-DECOMPOSITION.md and SPACING-NEAREST.md. Model decomposition has 45 source cases, 3,032 native assertions, 21 producer cases and seven harness tests. SPACING/NEAREST has 47 source cases, 1,354 native assertions, 13 producer cases and six harness tests.

The exact complete upstream demo_fraction, demo_set_exponent, demo_iachar and demo_spacing are retained with their license and source hashes. Adding EXPONENT alone does not make its complete original demo pass; remaining format and model-inquiry requirements remain explicitly rejected.

GNU 14.2.0 oracle limitations are retained separately. With valid INTEGER(8) `I=-HUGE(I)`, runtime SET_EXPONENT can narrow I and return +/-1, whereas literal folding and the candidate yield signed zero under the documented underflow policy. Another isolated constant-fold test returns half-HUGE for SET_EXPONENT(HUGE(X),MAXEXPONENT(X)); variable evaluation and the candidate retain HUGE. The receipt records exact flags, sources and outputs. Those boundaries use independent expected values/compile-only references, not claimed GNU execution agreement. Ordinary and variable-subnormal cases remain strict differential checks. Earlier DIM and CHARACTER compiler limitations remain documented, not erased.

## Helper-free original quick_sort and GNU-extension ISNAN

ISNAN is explicitly a GNU extension, not claimed as a Fortran 2018 intrinsic. It accepts finite REAL(4/8) scalar/array operands and returns default LOGICAL. Direct NaN/Infinity values continue to fail under the interpreter's existing finite-value policy. Source bindings, KIND/empty paths and public-IR metadata are checked independently. GNU references use `-fall-intrinsics`; a separate strict-standard probe without that option must reject.

The 45-case ISNAN suite includes eight wrappers preserving the complete original quick_sort and its two nested procedures without the earlier synthetic ISNAN helper. Its native tests add 52 checks and the runner has eleven self-tests. Finite sorting, values/permutations, ties and signed-zero value/index consistency are covered. Neither full NaN semantics nor execution of the entire utility library is claimed.

## Independent composition and source preservation

The new composition suite passes 37 source contracts and 37 staged GNU checks: 18 executions, twelve compile-only references and seven required source rejections. It adds 50 adversarial harness tests and 1,328 native assertions, including seven intrinsic-family mutation groups and eleven direct/function RNG stream controls. Four complete unchanged upstream programs and seven utility bodies (six RNG helpers plus the complete nested quick_sort closure) are pinned. Wrapper scaffolding is pinned separately so a substitute ISNAN helper cannot be concealed by changing a map hash.

Initial new-fixture failures used unsupported synthetic scaffolding: two-argument REAL conversion, rank-three RESHAPE/SUM/COUNT, rank-one vector gathering and mixed-length constructor inference. Only those new drivers/control expressions were replaced with supported equivalents, such as DBLE, explicit dimensions, section reductions and indexed oracle loops. Rank-three evaluation of the new intrinsics, independent value/state expectations, original body bytes and all interpreter guards were retained. The corrected focused native target and final empty-cache aggregate both pass. SHAPE already supports rank three; it was not the rejected restriction.

Earlier complete original wrappers remain rerun, including filter_matrix_rows and its unchanged dependencies, assert_le, positions_char_string, specification/SAVE helpers, fold_bounds, str_int and variable_names. Synthetic dependencies and adapted-only evidence remain labeled rather than presented as full originals.

## Untouched full source and historical limits

The 338,883-byte xutilities source retains SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both --check and execution reject before output at `9329:55: Total array element limit exceeded (131072)`. The fixed xbig(nmax) declaration in read_vec_data_unit uses nmax=10**8, above the unchanged 131,072-element cap. External-unit READ/CLOSE remain unsupported. No source reduction or special larger cap is used. Declaration analysis can precede body analysis, so this first location is not proof that every earlier routine executes.

GNU compiles/runs the unchanged original with -fcheck=all in its default extension mode and exits zero at the intentional final STOP after check_all_equal reports unequal values. Random-valued output is not compared byte for byte. Strict standard mode rejects the original nonstandard ISNAN extension. Full original-library execution remains unsupported by the interpreter.

Optional stronger-profile failures remain visible. Historical 0.31 records recursive-entry guard failures. The 0.34 feature-tree command `fpm test --profile release --flag '-fcheck=all -fbacktrace -ffpe-trap=invalid,zero,overflow'` failed eight native targets (six recursive-entry guards and two SIGFPE); its mean sweep passed 168/172 with four resolve_literal guard failures. There was no matched baseline for those exact flags, so those observations were not classified as new regressions. Logs remain under docs/verification/0.34.0/optional-strong-profile. That optional profile was not rerun for 0.37 and is not counted as passing. Official debug tests and source-oracle flags are distinct.

The corrected 0.34 list-staging checks, unchanged 4,096-REAL(8) smoke, 16 MiB list-directed cap and 65,536-byte formatted cap remain rerun. Windows and the standalone upstream FortFront test suite were not executed.

## Unchanged M_intrinsics survey

The pinned corpus contains 249 files: 20 complete original passes, 216 explicit rejections and 13 empty files. Against final 0.36 there are 4 new full passes (FRACTION, IACHAR, SET_EXPONENT and SPACING) and 0 pass regressions. The comparison records 4 changed first outcomes, separating complete passes from remaining diagnostics. All three retained RESHAPE probes match GNU. Before/after executable hashes and all 249 source hashes are checked. The three SPACING and four TINY exponent-notation differences are exactly Decimal-equal without tolerance, with raw outputs preserved. Signed-zero/integer/text distinctions, byte-exact ADJUSTR/REPEAT output and IACHAR's final CHARACTER record remain checked, with twelve comparator self-tests. Compact survey reports and the complete raw m-intrinsics-0.37-verification.zip are included under docs/verification/0.37.0/m-intrinsics. The raw archive contains the pinned sources, outputs, GNU evidence and scripts; no compiled executables. Historical verification evidence remains included.
