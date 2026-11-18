# Verification of prototype 0.25.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

The completed candidate source ZIP was extracted into a new directory whose path
contains spaces. `python3 scripts/verify.py` built without a build cache or a
network dependency download under the default 8 MiB stack limit and completed
all native and source suites. The shipped implementation, vendor files, tests,
examples, FPM configuration and verifier match the tested extraction byte for
byte. Final report copies and SHA-256 file manifest were assembled afterward;
the finished archive was inspected for source identity, manifest integrity and
absence of compiled files. The CLI's previously stale version string is fixed
and verified as 0.25.0.

An earlier combined clean run exposed missing CHARACTER length descriptors in
synthetic defined-output callback arguments. The descriptor setup was corrected,
the original fixtures retained, and a separate native callback regression added
before this final clean rerun. A second regression in the producer rejected
existing scalar CHARACTER truncation associations; scalar-only matching was
restored while fixed-length array checks remain strict. Separate native producer
coverage was added, and the existing source fixtures were retained.
Constant TRIM folding also promoted one former
runtime mismatch to a source rejection; its old source is unchanged, with a
new mutable-operand fixture retaining runtime-safety coverage. The earlier
diagnostic log is retained separately from the successful final log.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatables | 45/45 | 16 | 0 | 29 |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| character_arrays | 49/49 | 48 | 0 | 1 |
| character_parameters | 58/58 | 57 | 0 | 1 |
| character_procedures | 35/35 | 35 | 0 | 0 |
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
| formatted_arrays | 47/47 | 25 | 0 | 22 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| hyperbolic_intrinsics | 32/32 | 32 | 0 | 0 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| location_intrinsics | 58/58 | 55 | 0 | 3 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| logical_intrinsics | 41/41 | 35 | 0 | 6 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| module_use | 26/26 | 26 | 0 | 0 |
| mutable_modules | 42/42 | 33 | 0 | 9 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| optional_arguments | 31/31 | 31 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| release025_integration | 3/3 | 3 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| reshape | 88/88 | 33 | 0 | 55 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **4239/4239** | **3771** | **83** | **385** |

Zero failures. These are logical source cases, not process counts. Direct GNU
checks include execution, explicit compile-only checks and required compile
rejection. Compile-only is not execution agreement. SIMPLE lowered to PURE is
explicitly weaker. RESHAPE has 33 execution comparisons; its other 55 GNU
compilations are observations, not assertions, and remain in the last column.
One CHARACTER-constant case has a recorded GNU oracle discrepancy, described below,
and is also in that last column.

Additional checks:

- All 90 native Fortran programs, 17 CLI/resource contracts and
  277 Python harness self-tests pass; eight source-partitioner checks pass.
- Eight metadata CLI cases pass separately from the table. A source containing
  551 procedures, 124 generics, 423 PUBLIC/ONLY names and 2,997 symbols executes
  against GNU. The separate active runtime depth limit remains 64.
- The independent kind model checks 5,488 SELECTED_REAL_KIND calls in 69 programs;
  108 additional section-association cases match GNU and the numerical matrix
  checks 272 values with exact stdout agreement.
- All 4,713 pre-existing native/corpus/example Fortran sources from 0.24 remain
  byte-for-byte unchanged. Supported old expectations are promoted in manifests;
  no old source body was rewritten or removed to obtain passing results.
- Vendor patches 0038 and 0039 replay against 0.24 and reproduce all 457 vendor
  files exactly. Prior patches, MIT license and third-party attribution remain.
  Producer tests exercise strict metadata separately from adapter/runtime checks.
  The standalone upstream FortFront suite was not executed.

## New feature checks

Inferred-length default CHARACTER PARAMETER constants have 58 source cases:
57 supported GNU checks and one independently expected-output case with a known
oracle discrepancy. Scalar and rank-one/rank-two constants cover separate entity
lengths, empty strings/arrays, trailing blanks, scalar expansion, sections,
TRIM/concatenation/constructors, MERGE/PACK/RESHAPE, resource boundaries and
rejected nonconstant expressions. CHAR/ACHAR support INTEGER(4/8) scalar/arrays,
keywords and constant KIND=1; only ASCII codes 0 through 127 are supported.
Native tests add 21 adapter mutations, 18 runtime mutations and 20 independent
producer checks.

The 35 CHARACTER procedure cases include 22 GNU execution comparisons,
11 compile-only safety/boundary checks and two required GNU rejections.
They cover assumed-shape CHARACTER dummy arrays, fixed/assumed lengths, bounded
local/result specification lengths, explicit-shape array results, descriptor-only
LEN, sections, nested forwarding, empty/undefined values, once-per-entry lengths,
negative lengths, resource limits, wrong descriptors and unsupported declarations.
Native checks independently mutate adapter metadata, LEN trees and runtime state.

The 43 trigonometric cases cover REAL(4/8) SIN, COS and TAN on scalars, rank-one/two
arrays, constants, keywords, sections, elemental calls and empty arrays. They
include seven execution programs, 24 invalid-source cases, nine valid-but-unsupported
boundaries and three undefined-data safety cases. A separate native test executes
610 assertions, including corrupted metadata beneath empty expressions and
unevaluated KIND calls. REAL64 and original utility calculations use strict
numeric tolerances; this is not a claim of bitwise cross-platform math identity.

Three new synthetic integration cases combine inferred CHARACTER constants,
CHAR/ACHAR, dynamic-length array results, LEN, empty-array forwarding, trigonometric
expressions and formatted array output. Two successes match independently
specified output bytes and GNU. The third preserves the explicit boundary on
GNU-compilable dynamic-length CHARACTER PARAMETER declarations.

## Original utilities: precisely what runs

The full supplied source remains exactly 338,883 bytes, SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
It now passes the inferred-length CHARACTER module PARAMETER declarations at
lines 499–504. Both check and run modes reject with exit 1, no stdout, at line 595,
column 45: `ALLOCATABLE supports numeric arrays only`. The declaration is the
CHARACTER allocatable output dummy `words` in `read_words_line`. No unsupported
body is skipped. The complete original module/main still does not run in this
interpreter; broader allocation, intrinsics, control flow and I/O remain gaps.

Six additional original procedure bodies run inside new focused wrappers:
`concat_char_vec`, `sine_bound`, `half_sine_bound`, `sine_transform`,
`half_sine_transform` and `piecewise_sine`. The concat fixture retains original
CRLF body bytes; trigonometric bodies differ only by CRLF-to-LF normalization.
Both runners verify full-source and body hashes on every run. New wrappers and
drivers are separately authored. Earlier original-body suites also remain enabled.
These are original-body executions, not full original-program compatibility.

The untouched full source was separately recompiled and run by GNU with
`-fcheck=all` in default mode. Compilation and execution both exit 0; its main
intentionally finishes with an unequal-values diagnostic and ordinary STOP.
Random output is not compared byte for byte. Strict F2018 is not equivalent
because the unchanged supplied source contains GNU extensions.

## GNU oracle discrepancy

GNU 14.2 incorrectly infers length 3 for a zero-element CHARACTER concatenation
whose operand lengths sum to 4. The resulting valid RESHAPE PAD fixture is
rejected under strict flags; default GNU mode prints a truncated value. The
interpreter uses the length-sum rule and independently expected `abcd:` output.
The exact source, commands, diagnostics, outputs and standard reference are in
[GNU-EMPTY-CONCAT.md](../tests/character_parameters/GNU-EMPTY-CONCAT.md).
The runner separately records this known diagnostic. It does not count it as a
GNU agreement or an invalid-source rejection; a GNU version accepting the source
must instead produce the correct output. No claim is made that all interpreter
results agree with this compiler.

## Pinned M_intrinsics survey

All 249 pinned original entries were rerun on the same final clean executable:
236 nonempty programs and 13 empty placeholders.
4 complete originals pass and match GNU by output tokens;
232 are explicitly rejected. No prior pass regressed.
There are 19 changed first outcomes and
0 newly passing complete originals. No accepted-output mismatch,
interpreter crash or timeout was observed. See the
[survey report](verification/0.25.0/m-intrinsics/REPORT.md) for exact outcomes and
native compiler/source/environment limitations. Complete pinned sources, licenses,
commands and logs are in `m-intrinsics-0.25-verification.zip`. The survey and its
three synthetic RESHAPE probes are separate from the release-source counts above.

## Reproduce and limits

Put GNU Fortran, fpm and Python 3 on PATH and run `python3 scripts/verify.py`.
The Bash and PowerShell wrappers use that same portable verifier. Results remain
under tests/; clean logs, summary and provenance are in `docs/verification/0.25.0/`.
The prior report is preserved as `VERIFICATION-0.24.0.md`.

This remains a bounded interpreter prototype, not general modern Fortran support
or a production security sandbox. Deferred-length/allocatable CHARACTER, optional
CHARACTER dummies, dynamic explicit-length dummies, substrings, nondefault CHARACTER
kinds and other documented exclusions remain unsupported. Windows-compatible
source layout is retained, but Windows execution and the standalone upstream
FortFront suite were not run.
