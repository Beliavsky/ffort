# Verification of prototype 0.27.0

Recorded 15 November 2026 on Linux x86-64, GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14. Windows execution was not available.

## Fresh source archive verification

The source ZIP was extracted into a new directory whose path contains spaces.
`python3 scripts/verify.py` built without a build cache or network dependency
under the default 8 MiB stack limit and completed all native, CLI and source
suites. Shipped implementation, vendor source, tests, examples, FPM configuration
and verifier match the tested extraction byte for byte. Reports and the SHA-256
manifest were assembled afterward. The final ZIP was checked for source
identity, manifest integrity and absence of compiled files. The CLI reports 0.27.0.

An earlier clean run found two stale negative-test diagnostic expectations after
OPTIONAL arrays became supported. RESHAPE optional PAD and an OPTIONAL COUNT
specification mask still correctly reject, at their actual unsupported operations.
Only expected diagnostic strings changed; original Fortran sources and the
implementation did not. The complete final verifier was rerun from a new
extraction with no build cache. The earlier log is retained separately.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | No direct GNU assertion |
| --- | ---: | ---: | ---: | ---: |
| allocatable_assignment | 26/26 | 19 | 0 | 7 |
| allocatable_character | 35/35 | 30 | 0 | 5 |
| allocatable_dummies | 28/28 | 19 | 0 | 9 |
| allocatable_output | 7/7 | 5 | 0 | 2 |
| allocatables | 45/45 | 17 | 0 | 28 |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| array_results | 23/23 | 23 | 0 | 0 |
| arrays | 179/179 | 154 | 0 | 25 |
| automatic_arrays | 38/38 | 27 | 0 | 11 |
| character_arrays | 49/49 | 48 | 0 | 1 |
| character_intrinsics | 37/37 | 36 | 0 | 1 |
| character_parameters | 58/58 | 57 | 0 | 1 |
| character_procedures | 35/35 | 35 | 0 | 0 |
| character_substrings | 35/35 | 34 | 0 | 1 |
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
| forall | 85/85 | 39 | 0 | 46 |
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
| optional_character | 34/34 | 34 | 0 | 0 |
| optional_dim | 44/44 | 44 | 0 | 0 |
| optional_numeric_arrays | 67/67 | 41 | 0 | 26 |
| pack_intrinsic | 49/49 | 46 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| release025_integration | 3/3 | 3 | 0 | 0 |
| release026_integration | 6/6 | 6 | 0 | 0 |
| release027_integration | 10/10 | 10 | 0 | 0 |
| release_integration | 10/10 | 10 | 0 | 0 |
| reshape | 88/88 | 33 | 0 | 55 |
| rounding_intrinsics | 78/78 | 78 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| transform_composition | 26/26 | 20 | 0 | 6 |
| trigonometric_intrinsics | 43/43 | 43 | 0 | 0 |
| utilities_slices | 33/33 | 30 | 0 | 3 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **4626/4626** | **4080** | **83** | **463** |

Zero failures. Counts represent logical source cases, not process invocations.
Direct GNU checks include execution comparisons, explicit compile-only assertions
and required compiler rejections. Compile-only is not execution agreement.
SIMPLE lowered to PURE is explicitly weaker. Known compiler discrepancies and
interpreter-only safety policies retain independent expected results, rather
than being counted as GNU execution agreement.

Additional checks:

- All 102 native Fortran programs, 17 CLI/resource contracts,
  277 Python harness self-tests and eight partitioner checks pass.
- Eight metadata CLI cases include a GNU execution comparison with 551 procedures,
  124 generics, 423 PUBLIC/ONLY names and 2,997 symbols.
- The independent kind model checks 5,488 SELECTED_REAL_KIND calls in 69 programs;
  108 additional section-association cases match GNU and the numerical matrix
  checks 272 values.
- Of 4962 pre-existing native/corpus/example Fortran files from 0.26,
  4961 retain identical bytes. The preservation report identifies all
  changed files and their purpose; none are missing. Previously unsupported
  cases promoted to supported results are retained as original source evidence.
- Vendor patches 0043–0046 replay against 0.26 and reproduce all 457 vendor files
  exactly. Grouped CHARACTER length preservation is implemented once in 0043;
  0044 contributes scalar-substring rank, 0045 intrinsic result metadata, and
  0046 declaration-first array shadowing classification.
  MIT notices and earlier patch history remain. The standalone upstream
  FortFront suite was not executed.

## New feature checks

OPTIONAL CHARACTER supports bounded scalar and rank-one/rank-two dummies,
including documented allocatable forms, omission, direct absent forwarding,
PRESENT, exact lengths, definedness and copyback. Its focused suite covers
34 cases: 19 GNU executions and 15 compile-only checks. Producer, adapter and
direct-runtime mutations verify the metadata independently, including omitted
and unallocated actual descriptor corruption. The original `default_character`,
`default_character_nlen` and `set_optional_character` bodies retain exact source
bytes. See [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).

OPTIONAL numeric/logical array support has 67 focused source cases: 34 GNU
executions, three compile-only checks, four compiler rejections and 26
interpreter-only policy cases. Two of those 26 have separately recorded GNU
compiler ICEs for present array INDEX BACK with scalar strings, rather than
native output comparisons. The other policy cases avoid executing undefined
Fortran. Rank-one/two INTEGER(4/8), REAL(4/8), default LOGICAL, supported numeric
allocatables, forwarding, zero lengths, bounds, aliases and generic resolution
are checked; 250 native adapter/runtime mutations independently reject malformed
descriptors. The exact original real allocation helpers execute in a new wrapper.
The combined original integer/real slice retains its RECURSIVE prefix/calls and
is an explicitly tested unsupported boundary, not a supported-integer claim.

Scalar-base CHARACTER substring tests cover reads, writes, omitted bounds,
constants, automatic lengths, overlap, empty strings, LEN/KIND inquiries,
input actuals and alias checks. The 35 source cases include 17 GNU executions,
11 compile-only cases, six compiler rejections and one independent policy case.
Sixteen adapter and sixteen direct-runtime corruptions plus producer rank/length
checks remain separate evidence. The original `strip` body is preserved.
Opposite int64-bound cases are compile-only because GNU 14.2 length arithmetic
is not a reliable execution oracle there. See
[CHARACTER-SUBSTRINGS.md](CHARACTER-SUBSTRINGS.md).

INDEX, LEN_TRIM, ADJUSTL and ADJUSTR support bounded scalar/rank-one/rank-two
execution and documented keyword/KIND/absence behavior. Bounded LEN_TRIM-based
specification expressions permit the exact original `quote` body. The 37 cases
have 16 GNU executions, 17 compiler rejections, three compile-only checks and
one separately documented GNU 14.2 compiler ICE for legal dynamic empty
CHARACTER descriptor inquiries. The ICE is not an execution comparison.
Independent native checks cover producer metadata, malformed AST/IR, empty
and inquiry contexts, and optional INDEX BACK. See
[CHARACTER-INTRINSICS.md](CHARACTER-INTRINSICS.md).

Ten combined cases exercise the CHARACTER and OPTIONAL array features with existing allocatable
arrays and FORALL. Seven execute against GNU and independently specified output;
two absent-value safety tests and one writable-substring boundary use compile-only
GNU checks. Five original utility bodies are combined in one new module/driver,
with hashes and source ranges checked before execution. Original procedure
bodies, new wrappers and synthetic cases are identified separately.

The earlier 73 date examples were retained unchanged and pass again after
correcting the initially over-reserved INDEX name. Five new name-shadowing
cases and producer tests cover scalar/array declarations, result names, user
procedures and a generic named INDEX. No adapter comparison was weakened.

## Exact original utilities boundary

The original file remains exactly 338,883 bytes with SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`. Both check and run modes reject with status 1 and
no stdout at:

`1829:62: Only rank-one and rank-two arrays are supported`

It now passes the earlier OPTIONAL CHARACTER, LEN_TRIM and OPTIONAL numeric-array gates. This is a
specific first-diagnostic advancement, not a claim that the complete utility
library executes. Unsupported declarations and bodies remain explicit limits.
The full source is never rewritten, partitioned or skipped to obtain this result.

The same untouched file was freshly compiled and run with GNU 14.2 using
`-fcheck=all` in default mode. Both exit zero; the original driver deliberately
stops at its final `check_all_equal([2,3],...)` call. The file uses nonstandard
ISNAN, so this is not strict standard-mode acceptance. Random-valued output is
not claimed to agree byte for byte. Logs and source identity are retained.

## Pinned M_intrinsics survey

All 249 unchanged files at pinned commit
`fc14233036d910e3678d350efc24609e11475067` were checked using the final clean
0.27 executable: 4 complete programs pass,
232 nonempty programs reject,
and 13 are empty placeholders.
There are 0 new complete passes and
0 regressions against the recorded 0.26 baseline.
2 first outcomes changed. Exact program
lists, reasons, native source/compiler limitations and comparisons are in
[the survey report](verification/0.27.0/m-intrinsics/REPORT.md). A focused probe
passing is not a complete original-example pass.

The separately reproducible `m-intrinsics-0.27-verification.zip` contains original
sources, licensing, harnesses and per-case logs. Compact catalogs and hashes are
also included in this source package.

## Reproduction and scope

Run `python3 scripts/verify.py` with fpm and gfortran on PATH. Bash and PowerShell
wrappers remain available. Windows-friendly paths are provided but Windows was
not executed. Strict independent source, producer, adapter and runtime checks
remain enabled. Debug verification is not full Fortran conformance or a sandbox
security guarantee. Scalar allocatable CHARACTER, unsupported substring bases
and writable substring actuals, broader I/O, ranks and unlisted intrinsics remain
outside the documented subset. Earlier release reports preserve earlier results.

Detailed machine-readable evidence is under `docs/verification/0.27.0/` and tests/.
