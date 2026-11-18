# Verification of prototype 0.22.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Clean source archive verification

The source ZIP was extracted into a new directory whose path contains spaces.
`python3 scripts/verify.py` built it without a build cache or dependency download
and completed every native and source suite successfully under the default
8 MiB stack limit. The shipped implementation, vendor files, tests, examples,
FPM configuration and verifier match that tested extraction. Report copies,
documentation and the SHA-256 file manifest were finalized afterward.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
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
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| release_integration | 6/6 | 6 | 0 | 0 |
| reshape | 63/63 | 29 | 0 | 34 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| utilities_slices | 33/33 | 31 | 0 | 2 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **3817/3817** | **3452** | **83** | **282** |

Zero failures. These are logical source cases, not process invocations. Direct
GNU checks include successful execution, explicit compilation-only checks and
expected compile rejection. Compile-only is not an execution comparison. SIMPLE
references lowered to PURE remain explicitly weaker. The RESHAPE suite has 29
execution comparisons; its other 34 GNU compilations are observations rather
than acceptance/rejection assertions and are conservatively in the final column.

Additional checks:

- All 71 native Fortran programs, 17 CLI/resource contracts and 277 Python
  harness self-tests pass. Eight reference-partitioner checks also pass.
- Eight metadata CLI cases pass, separately from the source table. A synthetic
  source with exactly 551 procedures, 124 generics, 423 PUBLIC/ONLY names and
  2,997 symbols executes against GNU. Capacity and over-cap boundaries preserve
  the independent 64-active-call-frame limit; a 65-deep called chain still fails
  safely. Native metadata tests contain 23 boundary/graph/storage checks.
- The independent kind model checks 5,488 SELECTED_REAL_KIND calls in 69
  generated programs. A further 108 section-association cases match GNU, and
  the numerical matrix checks 272 values with exact stdout agreement.
- All 457 vendor files are byte-for-byte identical to 0.21.0. Existing patches,
  licenses and attribution are retained; this release needs no new vendor patch.
- All 4,317 pre-existing native/corpus/example Fortran sources from 0.21.0
  remain byte-for-byte unchanged. Capacity expectations were updated in the
  harnesses rather than rewriting old source fixtures.

## New feature and combined checks

COUNT-bound coverage has 42 source cases, including 23 GNU executions, three
compile-only checks, seven compiler rejections and nine safety/subset cases.
The 41 native COUNT assertions mutate bound metadata and check frozen entry
values, copied dummy masks, empty results, undefined reads, work and frame caps.

PACK has 49 source cases: 26 successful GNU executions, seven compile-only
checks, 13 compiler rejections and three safety-only cases. Native tests add
225 assertions. GNU 14.2 crashes on the zero-length CHARACTER PACK oracle and
accepts differing CHARACTER lengths without diagnosis; these cases are explicitly
compile-only, never represented as successful runtime matches.

RESHAPE has 63 source cases plus 46 native assertions. Tests cover both result
orders, repeated PAD, all supported types/kinds, empty and exact-limit results,
wide extent overflow, optional slot association, malformed IR and KIND validation.
SHAPE length must be statically one or two, and direct rank-two declaration/PARAMETER
initializers remain excluded; constant rank-one initializers are supported. Full array-language support is not claimed.

The combined COUNT/PACK/RESHAPE driver retains exact original true_pos_func,
positive_int_vec, matrix_from_vec and vector function bodies. The runner checks
original bytes, normalized bodies, source lines and fixture hashes, then compares
independent literal expectations and strict GNU execution. It composes automatic
results, PACK/RESHAPE, ORDER, sections, SUM/DIM, DOT_PRODUCT and MATMUL, including
empty and changing shapes. Wrappers and drivers are new, not original main code.

A further 26 cross-feature composition cases cover CHARACTER and LOGICAL
transformations, exact INTEGER(8), nested KIND, ORDER/PAD produced by PACK,
constant composition and empty-output safety. Twenty match strict GNU execution;
six assert interpreter safety failures without executing invalid oracle inputs.

Two supplemental initializer probes confirm rank-one constant RESHAPE against
GNU and preserve the direct rank-two initializer rejection. Their sources and
results are in verification/0.22.0/initializer-probes/.

## Full original utilities boundary

The untouched 338,883-byte utilities file passes source preservation and exact
reconstruction checks. Check and run modes now reject at line 493, column 24:
`Only PARAMETER module data is supported`, with status 1 and no stdout. This
advances beyond the former PUBLIC-name cap without skipping unsupported bodies.
The entire original file still does not compile or execute in this interpreter.
Allocatable storage, CHARACTER array procedure arguments/results, mutable module
state, rank three, broader control flow/intrinsics and I/O remain major gaps.

GNU Fortran was independently rerun on the exact original using its default mode
and `-fcheck=all`: compile and run both exit 0. The driver intentionally ends with
its unequal-values diagnostic and ordinary STOP. Strict F2018 compilation is
not an equivalent reference because the original uses GNU extensions such as
ISNAN and GETCWD. No portability rewrite was made.

## Reproduce

Put GNU Fortran, fpm and Python 3 on PATH and run `python3 scripts/verify.py`.
The PowerShell and Bash wrappers run that same portable verifier. Per-suite
results remain under tests/; the clean build log, summary, original-file evidence
and provenance are under docs/verification/0.22.0/. The previous verification
report remains in VERIFICATION-0.21.0.md.

This is a bounded interpreter prototype, not general modern Fortran support or
a production security sandbox. Windows source compatibility is intended, but
Windows was not executed. See METADATA-LIMITS.md, AUTOMATIC-ARRAYS.md, PACK.md
and RESHAPE.md for the precise supported contracts.
