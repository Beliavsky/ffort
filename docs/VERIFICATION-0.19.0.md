# Verification of prototype 0.19.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete candidate was archived and extracted into a new directory whose
path contains spaces. `python3 scripts/verify.py` built and tested it without a
build cache or dependency downloads. All interpreter source, native tests, runnable corpus cases, examples, vendored
source and FPM configuration in the final archive match this tested extraction.
The reference-only utility partitioner was then corrected to keep nested internal
procedures with their parent and independently reverified, along with the focused
utility cases and full-file boundary. The audit records that bounded post-run
change; no interpreter or runnable fixture changed. Reports, documentation,
result copies and the file manifest were finalized afterward.

| Suite | Interpreter cases | Direct GNU checks | Weakened SIMPLE references | GNU comparison skips |
| --- | ---: | ---: | ---: | ---: |
| argument_association | 145/145 | 145 | 0 | 0 |
| array_expression_arguments | 49/49 | 49 | 0 | 0 |
| array_intrinsics_independent | 234/234 | 234 | 0 | 0 |
| array_limits | 30/30 | 26 | 0 | 4 |
| arrays | 179/179 | 154 | 0 | 25 |
| character_arrays | 49/49 | 48 | 0 | 1 |
| class_type_bound | 44/44 | 40 | 0 | 4 |
| derived_date_independent | 73/73 | 73 | 0 | 0 |
| derived_select_integration | 18/18 | 18 | 0 | 0 |
| derived_types | 43/43 | 38 | 0 | 5 |
| elemental_functions_independent | 135/135 | 115 | 13 | 7 |
| elemental_subroutines_independent | 128/128 | 107 | 3 | 18 |
| generic_interfaces | 51/51 | 51 | 0 | 0 |
| independent | 226/226 | 206 | 0 | 20 |
| integer_kinds_independent | 23/23 | 11 | 0 | 12 |
| keyword_arguments_independent | 446/446 | 446 | 0 | 0 |
| logical_initializers | 14/14 | 14 | 0 | 0 |
| mean_programs_independent | 172/172 | 167 | 0 | 5 |
| module_functions | 89/89 | 76 | 0 | 13 |
| numerical_procedures | 88/88 | 85 | 0 | 3 |
| program_forms | 87/87 | 84 | 0 | 3 |
| pure_simple_independent | 121/121 | 54 | 67 | 0 |
| rank_two | 136/136 | 136 | 0 | 0 |
| rank_two_sections | 269/269 | 262 | 0 | 7 |
| release_integration | 3/3 | 3 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| utilities_slices | 33/33 | 32 | 0 | 1 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **3,316/3,316** | **3,054** | **83** | **179** |

Zero failures. Counts are logical source cases, not every subprocess invocation.
GNU checks include execution, compilation-only and expected rejection; skips are
not passes. SIMPLE-to-PURE comparisons remain explicitly weakened references.
The utilities suite includes one supported-kind-model check whose values are not
compared with GNU's wider real kinds. The source-cap suite compares three larger
valid programs with GNU; its other seven cases test interpreter limits.

Additional checks:

- All 56 native Fortran test programs, 17 CLI/resource
  contracts and 277 Python harness self-tests pass. The final
  reference-partitioner correction also passes eight dedicated self-checks.
- The independent optional-argument matrix checks 5,488 SELECTED_REAL_KIND calls
  in 69 generated programs against the supported REAL32/REAL64 model. It covers
  every optional slot mask, keyword permutations, mixed positional prefixes,
  INTEGER(8) extremes and negative result codes. This is a policy-model oracle,
  not a claim that GNU offers only these kinds.
- Native source-cap tests exercise nine API byte/token boundary and recovery
  checks. CLI tests cover 10 cases, including exact/above caps, CRLF byte
  accounting, old-limit regressions and unchanged ASCII/line-length rejection.
- The exact 338,883-byte supplied source is checked and run through the CLI.
  Both modes pass the size gate and reject `.in.` at line 25, column 38 with
  status 1 and no program output. The complete utility library is not supported.
- The original file is preserved byte for byte. The 549 top-level routine fragments (retaining two internal procedures) and
  eight main-program blocks reconstruct it exactly, including CRLF newlines.
  Regenerating the partition reproduces all 563 partition/map files. All 27
  extraction occurrences in the selected utility harnesses match the original
  procedure text apart from newline normalization.
- Five runnable utility groups cover 15 original routine bodies. They exercise
  logical runs/search, factorial, generic selection, activation functions and
  bounded values. Other utility harnesses assert specific fail-closed diagnostics,
  rather than accepting any error as a successful boundary test.
- The previous generated nested-section and REAL32/REAL64 arithmetic matrices
  are included in the complete verifier and still pass.

See [the complete clean run](verification/0.19.0/final-clean-room-full-verification.log),
[the machine-readable summary](verification/0.19.0/final-summary.json),
[the utility-source audit](verification/0.19.0/utility-source-audit.json),
[the reference-only correction audit](verification/0.19.0/reference-partition-correction.json), and
`tests/*/results.json`. Every suite result records the clean executable SHA-256.
`tests/utilities_slices/full-source-result.json` records the exact-file rejection;
`kind-matrix-results.json` records the 5,488-call model matrix.

## Scope and limitations

Source capacity is now 1,048,576 bytes and 262,144 tokens. Both are shared
build-time constants in `src/fi_limits.f90`; token storage grows on demand.
Array, symbol, procedure, instruction, nesting, CHARACTER, PRINT and runtime-work
limits remain separate. The default array cap remains 131,072 and the default
work budget remains 1,000,000 steps. See [source limits](SOURCE-LIMITS.md).

SELECTED_REAL_KIND supports only the interpreter's REAL32/REAL64 model. It does
not add storage for wider real kinds. The utility file still requires many
unsupported features, including defined operators, OPTIONAL arguments,
allocatables, dynamic/array function results, rank-three arrays, module-to-module
USE, ELSE IF, EXIT and general external/file I/O. Raw fragments preserve their
dependencies and are reference units, not independently compilable modules.
The working harnesses explicitly reduce module setup and driver code without
rewriting procedure algorithms. See [the detailed contract](UTILITIES.md) and
[quick-start commands](../tests/utilities_slices/README.md).

The supplied source compiles and runs with GNU Fortran's default mode. Its own
last intentional unequal-value check stops the driver. Strict F2018 compilation
rejects the nonstandard ISNAN call. Those source/oracle facts are separate from
the interpreter's unsupported subset.

Windows, other compilers, upstream-wide tests, forced allocation failures and
exhaustive malformed-IR fuzzing were not run. This is portable source, not a
prebuilt Windows executable or an OS security sandbox. Selected passing tests
are not an estimate of complete Fortran conformance.

## Preservation and provenance

All 3,414 prior native-test, corpus and example Fortran source files
are byte-identical to 0.18.0. Source-cap expectations in two Python harnesses now
read the configured constant. Historical verification through
[0.18.0](VERIFICATION-0.18.0.md) is retained.

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
The new documented SELECTED_REAL_KIND producer patches replay without fuzz on the
0.18.0 vendor tree and reproduce the final vendor files byte for byte; see
[patch replay evidence](verification/0.19.0/vendor-patch-replay.json).
Complete vendored library sources, the FPM path dependency and MIT notices
remain included. The supplied utility code keeps its own source provenance.
GNU Fortran builds the interpreter and supplies test oracles; it is never used
as the execution backend for interpreted programs.
