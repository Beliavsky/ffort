# Verification of prototype 0.21.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Clean source archive verification

The complete candidate source ZIP was extracted into a new directory whose path
contains spaces. `python3 scripts/verify.py` built it without a build cache or
dependency download and ran the full native and source suite successfully.
The shipped interpreter, vendor library, native tests, runnable cases, examples,
FPM configuration and verifier match that tested extraction. Reports, result
copies, documentation and the SHA-256 file manifest were finalized afterward.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | GNU comparison skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| character_arrays | 49/49 | 48 | 0 | 1 |
| class_type_bound | 44/44 | 40 | 0 | 4 |
| control_flow | 57/57 | 25 | 0 | 32 |
| defined_operators/optional_operands | 6/6 | 6 | 0 | 0 |
| defined_operators | 19/19 | 19 | 0 | 0 |
| derived_date_independent | 73/73 | 73 | 0 | 0 |
| derived_select_integration | 18/18 | 18 | 0 | 0 |
| derived_types | 43/43 | 38 | 0 | 5 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| hyperbolic_intrinsics | 32/32 | 32 | 0 | 0 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| logical_intrinsics | 40/40 | 33 | 0 | 7 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| module_use | 26/26 | 26 | 0 | 0 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| optional_arguments | 31/31 | 31 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| release_integration | 6/6 | 6 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| utilities_slices | 33/33 | 31 | 0 | 2 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **3,635/3,635** | **3,322** | **83** | **230** |

Zero failures. Counts are logical source cases, not every process invocation.
Direct GNU checks include execution, compilation-only checks and expected compile
rejections. A compile-only check is not an execution comparison. Skips are not
GNU passes. SIMPLE-to-PURE references remain explicitly weakened comparisons.

Additional checks:

- All 67 native Fortran test programs, 17 CLI/resource contracts
  and 277 Python harness self-tests pass. Eight additional
  reference-partitioner checks pass, including nested internal-procedure preservation.
- The independent kind model checks 5,488 SELECTED_REAL_KIND
  calls in 69 generated programs. It models supported REAL32/REAL64,
  not GNU's wider-kind behavior.
- An additional 108 generated section-association cases match GNU,
  and the numerical matrix checks 272 values with exact stdout agreement.
- Vendor patches 0032 and 0033 replay in numeric order against the preserved
  0.20 vendor tree with fuzz zero. All 457 vendor files match byte for
  byte. Earlier patches, licenses and provenance remain included.
- All 4,246 pre-existing native/corpus/example Fortran sources
  from 0.20 remain byte for byte unchanged. Newly supported rejection fixtures
  were promoted to execution with their generators kept consistent. New regression
  sources are separate additions.
- Eight original utility bodies are independently compared to the untouched input,
  allowing only newline normalization. Their exact source ranges and hashes are
  in original-utility-bodies.json. The true_pos_count caller is explicitly adapted;
  the other new drivers and wrappers are not represented as original utility code.
- The original 338,883-byte utilities source and its exact byte reconstruction
  pass preservation checks. Its full-file check/run modes still reject at the
  accessibility-name capacity on line 26 without output. The complete utilities
  module remains outside this prototype's supported subset.

## New feature checks

The automatic-array suite covers scalar INTEGER dummy bounds, SIZE and bound
inquiries, lower bounds, once-per-entry/frozen shape, repeated/nested invocations,
INTEGER/REAL kinds, CHARACTER locals, PURE procedures, undefined OUT descriptor
inquiries, zero/negative extents, exact limits, arithmetic/index overflow and
unsupported bounds. Native tests also corrupt adapter/runtime IR metadata,
check fresh definition flags and exhaust shared work budgets.

Array-function results cover numeric/logical rank one/two, fixed and automatic
bounds, implicit/explicit result names, repeated/nested calls, defined operators,
generics, read-only expression actuals, constructors and MATMUL, ownership beyond
return, KIND non-evaluation, empty results that still execute their bodies, partial
initialization, shape/frame/temporary caps, and malformed result metadata.
The 23 focused sources have 14 GNU execution oracles, seven compile-only
compatibility checks and two GNU compile rejections. Runtime-policy cases do not
pretend that GNU enforces this interpreter's safety limits.

SINH/COSH/TANH checks cover REAL(4/8), scalars/arrays, keywords, constants,
non-finite rejection, invalid calls, empty arrays and unevaluated KIND. The native
suite exercises 466 assertions. A cross-feature source combines the unchanged
original sech body with automatic scratch arrays and ordinary array results,
rank-one/rank-two hyperbolic calls, reductions/DIM, and zero extents. Its expected
values are independently calculated, and GNU is a second oracle.

Exact retained utility bodies execute for normalize, diff_vector_int,
diff_vector_real, diff_matrix_real, growing_mean_vec, num_obs_bins and sech.
The existing normalize/sech boundary fixtures are now successful execution cases.

## Reproduce and interpret the evidence

Put GNU Fortran, fpm and Python 3 on PATH and run `python3 scripts/verify.py` from
this source root. The PowerShell and Bash wrappers call the same Python verifier.
No build tools, binaries or dependency cache are shipped. Per-suite results and
compiler commands remain under tests/, and the full clean-build log and summary
are under docs/verification/0.21.0/. Windows source paths are supported by the
portable scripts, but this release was not executed on Windows.

This remains a bounded prototype, not general modern Fortran support or a
production security sandbox. See AUTOMATIC-ARRAYS.md, ARRAY-RESULTS.md and
HYPERBOLIC-INTRINSICS.md for supported forms and explicit exclusions. Neither the
new smaller utility fixtures nor passing checks imply full-library compatibility.
