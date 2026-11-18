# Verification of prototype 0.39.0

Recorded 15 November 2026 on Linux x86-64 using GNU Fortran 14.2.0, fpm 0.13.0 alpha and Python 3.12.14. Windows was not executed.

## Fresh archive and complete regression

A source ZIP was extracted into a fresh directory with spaces in its path. With no build cache or network dependency, `python3 scripts/verify.py` rebuilt and passed all native, CLI, source and harness checks under the default 8 MiB stack limit. Final implementation, vendor sources, source tests, examples, configuration and verifier match that extraction byte for byte. Reports and manifest were assembled afterward. Archive CRC, manifest, tested-source identity and absence of compiled files were independently checked.

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
| erf_bessel | 63/63 | 63 | 0 | 0 |
| erfc_scaled | 35/35 | 35 | 0 | 0 |
| explicit_dummy_bounds | 57/57 | 57 | 0 | 0 |
| exponent_inquiries | 63/63 | 63 | 0 | 0 |
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
| release039_integration | 32/32 | 32 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| repeat_intrinsic | 31/31 | 30 | 0 | 1 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| rounding_inverse_hyperbolic | 66/66 | 66 | 0 | 0 |
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
| **Total** | **6659/6659** | **5923** | **83** | **653** |

Zero failures. Counts are logical cases, not invocations. Direct GNU checks include execution comparisons, compile-only assertions and required source rejections. Compile-only is not execution agreement; SIMPLE lowered to PURE is a weaker oracle. Safety-policy and known compiler-difference cases remain explicitly separated.

- All 176 native programs and 896 harness self-tests pass, plus 17 CLI/resource contracts, eight partitioner checks, 39 additional POINTER source rejections and one ASSOCIATED runtime safety probe outside the table.
- Eight metadata cases include a GNU utility-scale comparison with 551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- Retained matrices cover 5,488 SELECTED_REAL_KIND calls in 69 programs, 108 section-association cases and 272 numerical values. The independent rounding generator verifies 208 exact model values in a source-table case; it is not counted as additional independent programs.
- All 6990 prior Fortran tests/native/examples are byte-identical to certified 0.38: 6821 source-program fixtures and 169 native test files. New manifest expectations and scaffolding are distinguished from original program bytes.
- Cumulative patches 0067–0069 reproduce all 457 vendor files, including the 104-entry registry. An independent canonical core patch replays all implementation/vendor files. Licenses, original hashes and patch ledgers are retained. The standalone upstream FortFront suite was not run.

## REAL rounding and inverse hyperbolic functions

AINT/ANINT preserve REAL(4/8) argument semantics before optional result-KIND conversion; ASINH/ACOSH preserve supported elemental kinds/shapes. Domain and finite-result guards, full operand metadata/cycle validation, source bindings, KIND inquiry and empty-expression paths remain independently checked. AINT/ANINT do not narrow through an integer conversion. Signed-zero expectations describe this explicitly tested IEEE implementation contract, not a universal guarantee about every Fortran processor.

GNU 14 variable evaluation can narrow before rounding for selected optional-KIND boundaries, while its constant folding and independent argument-first expectations agree with this interpreter. Exact O0/O2 receipts are retained and those cases are compile-only GNU boundaries, not claimed execution agreement. The unchanged AINT, ANINT, ASINH and ACOSH demonstrations are separate complete GNU comparisons.

The new rounding runner was hardened to Decimal comparisons, exact integer/real matching, signed-zero distinctions, finite tolerances and no binary64 coalescing. Its independent matrix generator had discarded 32 negative-zero expectation signs through Python integer truncation; only the generator and new expected results were corrected. All Fortran fixture bytes remain unchanged. Initial runner snapshots and adversarial false-positive evidence are retained. See [rounding and inverse hyperbolics](ROUNDING-INVERSE-HYPERBOLIC.md).

## Bounded ERF/Bessel support and independent accuracy

ERF accepts finite REAL4/8 inputs. The six Bessel names support scalar/elemental ranks 1–3 with `abs(X) <= 2**20`; JN/YN support the two-argument form and INTEGER4/8 orders 0–32. Y functions additionally require `X >= 2**(-20)`. Negative orders, larger domains and three-argument transformations remain outside this bounded contract. Inputs are checked before host evaluation or integer narrowing; nonfinite results and REAL4 overflow reject safely. The original Y0(0) demonstration remains a singularity rejection, with no source substitution.

Separately from the ordinary source cases, 1818 exact-binary inputs pass independent 120-digit mathematical references across seven functions and both kinds. ERF uses 2 ULP REAL4 / 4 ULP REAL8 budgets. Nonoscillatory Bessel tests use 4 epsilon REAL4 / 64 epsilon REAL8 relative budgets plus twice the smallest subnormal. Oscillatory and root-neighbor tests use 16 epsilon times the larger of absolute reference and oscillation amplitude, plus twice the smallest subnormal. These are explicitly scoped mathematical budgets, not a relaxed generic comparator or an exhaustive accuracy theorem.
- REAL(4): 903 points; maximum observed budget fraction 0.25; 1 recorded GNU precision differences and 0 unexpected differences.
- REAL(8): 915 points; maximum observed budget fraction 0.359847; 0 recorded GNU precision differences and 0 unexpected differences.

The independently recorded GNU REAL4 J16(8) precision difference is recognized only for its exact argument/order/kind and observed result; other unexpected GNU errors fail verification. Six complete finite original ERF/Bessel examples execute unchanged, separately from the mathematical reference matrix. Decimal-aware source comparisons preserve integer/text, signed zero and nonzero tiny values; any numerical tolerance remains explicitly scoped. See [ERF/Bessel contract and budgets](ERF-BESSEL.md).

## Exponent-model inquiries and composition

MINEXPONENT/MAXEXPONENT return scalar default INTEGER model information for eligible REAL4/8 operands without reading whole undefined, unallocated, absent OPTIONAL or undefined-pointer data. The bounded operand grammar, source binding and metadata/DAG guards are retained; subobject inquiries and unlisted specification expressions remain unsupported. The complete original MINEXPONENT example passes. MAXEXPONENT's original still has separate unsupported formatting/REAL128 use, so it is not claimed as a complete pass. See [exponent-model inquiries](EXPONENT-MODEL-INQUIRIES.md).

The release039_integration suite independently combines kinds, rank1/2/3 elemental values, CSHIFT, ASSOCIATED, ERFC_SCALED, inquiries, source shadows and atomic failure paths. Ordinary numerical comparisons use exact Decimal values with signed-zero distinctions; a Bessel amplitude budget does not leak into unrelated comparisons. Independent optional-KIND GNU boundary evidence, native malformed-IR assertions, source hashes and final results are retained in its receipt. Initial new-fixture scope corrections are explicitly retained; no original source or core guard was weakened to obtain a pass.

All earlier suites and original-body wrappers were rerun. Historical GNU limitations, ERFC_SCALED's 439-point mathematical evidence, processor-specific finite policies and compile-only boundaries remain documented. The optional 0.34 guarded release profile failed eight native targets (six recursive-entry guards and two SIGFPE cases) and four mean cases; no matched baseline existed for those exact extra flags. It was not rerun or counted as passing here. Official fresh debug verification and GNU source oracles are distinct. Windows and the standalone upstream FortFront test suite were not executed.

## Untouched utility source

The unchanged source has 338,883 bytes, SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Check and execution both reject with zero stdout at `9329:55: Total array element limit exceeded (131072)`. The declaration xbig(nmax), nmax=10**8, exceeds the unchanged 131,072-element cap. No original rewrite or cap increase bypasses it. Declaration analysis precedes some body analysis, so this first diagnostic does not establish execution support for all earlier routines. External READ/CLOSE remain unsupported.

GNU compiles/runs the unchanged original with -fcheck=all in default extension mode, exiting zero at its intentional final STOP after check_all_equal reports unequal values. Random-valued output is not compared byte for byte. Full original-library execution by this interpreter is not claimed.

## Complete unchanged M_intrinsics survey

All 249 pinned source hashes match certified 0.38. Results: 38 complete original passes, 197 check-time rejections, 1 controlled runtime domain rejection and 13 empty placeholders. There are 11 new complete passes and 0 regressions. The 12 changed outcomes are separately classified in the comparison report rather than described wholesale as successes. All three retained probes match GNU; before/after executable identity is verified. The unchanged BESSEL_Y0 source checks successfully, then rejects X=0 at runtime with status2, zero stdout and its exact domain diagnostic. GNU prints -Infinity at that pole; this is a controlled interpreter policy boundary, not a crash, complete pass or numerical mismatch.

Exact Decimal exponent-notation comparisons preserve numerical values without tolerance; signed-zero/integer/text and significant CHARACTER distinctions remain. The complete raw m-intrinsics-0.39-verification.zip is included with compact reports under docs/verification/0.39.0/m-intrinsics, including source, raw output, GNU evidence and scripts without compiled executables.
