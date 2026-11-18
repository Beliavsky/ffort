# Verification of prototype 0.18.0

Recorded 14 November 2026 on Linux x86-64 with GNU Fortran 14.2.0,
fpm 0.13.0 alpha and Python 3.12.14.

## Clean archive verification

The complete candidate was archived and extracted into a fresh directory whose
path contains spaces. `python3 scripts/verify.py` built from source without a
build cache or dependency downloads and completed successfully. All executable
source, native tests, corpus source, verifier scripts, examples, vendored source
and FPM configuration in the final ZIP match that tested extraction. Documentation,
verification reports, result copies and the file manifest were finalized afterward.

| Suite | Interpreter checks | Direct GNU checks | Weakened SIMPLE references | GNU skips |
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
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **3,273/3,273** | **3,019** | **83** | **171** |

Zero failures. GNU checks include execution, compilation-only and expected
rejection. Skips are not passes. SIMPLE-to-PURE references are explicitly weakened
comparisons, not native GNU support for Fortran 2023 SIMPLE.

Additional checks:

- All 53 native Fortran test programs, 17 CLI/resource contracts and
  277 Python harness self-tests pass.
- The 108 generated nested-section programs and the 272-value REAL32/REAL64
  arithmetic matrix retain independent Python/GNU comparisons.
- The requested CHARACTER array example and original CLASS/type-bound date
  example have stdout byte-identical to GNU Fortran. The named generic `twice`
  program produces matching values, differing only in list-directed spacing.
  The previous scalar-derived date and SELECT CASE examples still match GNU
  byte for byte. Exact sources and hashes are retained.
- Three additional integration cases combine generic dispatch with CHARACTER
  array construction, REAL64 array arithmetic, CLASS-bound CHARACTER results
  and captured defined output. They all match independently specified GNU values.
- The new generic REAL64 ELEMENTAL-expression regression independently checks
  producer result type/kind/rank. Adapter result checks remain enabled.
- The final native integration test validates nine malformed bound-call metadata
  corruptions, including absent/empty implicit receiver arguments, without a
  bounds exception. Ordinary and generic call paths remain independently checked.
- CHARACTER tests include typed/empty constructors, lengths, padding, rank-two
  sections, overlap, concatenation, empty arrays, safe failures and native
  producer/adapter/runtime mutations. CLASS tests include distinct same-named
  types across module scopes, keywords, visibility, receiver mutation, captured
  child output, status handling and unsupported boundaries.

See [the complete clean run](verification/0.18.0/final-clean-room-full-verification.log),
[the machine-readable summary](verification/0.18.0/final-summary.json),
[exact-program evidence](verification/0.18.0/exact-programs.json), and
`tests/*/results.json`. Every current suite records the clean executable SHA-256.

## Scope and oracle limits

This remains a deliberately restricted interpreter, not a complete Fortran
processor or security sandbox. The new features have bounded contracts:
[CHARACTER arrays](CHARACTER-ARRAYS.md), [named generics](GENERIC-PROCEDURES.md),
and [CLASS/type-bound calls](CLASS-TYPE-BOUND.md).

CHARACTER array dummies/results, runtime-length constructors, substrings,
nondefault CHARACTER kinds and constructor implied DOs remain unsupported.
Named generics use exact supported type/kind/rank selection, without optional
arguments, external interface bodies, USE renaming or merging imported generics.
CLASS support is scalar and exact-type: no inheritance, changing dynamic type,
CLASS locals/results, unlimited polymorphism, named PASS or NOPASS. Defined
output captures bare DT and list-directed transfers; no READ, DT tag/value lists,
general external units, arbitrary file I/O or recoverable I/O-error system is added.

The array cap remains 131,072 elements, configurable with the single
`max_array_elements` constant in `src/fi_ir.f90`. Source bytes, CHARACTER length and
expanded PRINT values remain independently bounded at 65,536, and default work
remains 1,000,000 steps. These are interpreter-region limits, not OS-wide memory
limits. RANDOM_NUMBER retains its documented deterministic per-execution stream;
GNU RNG values are not compared for equality. Safety-policy/undefined behavior
probes have explicit GNU skips. Passing these selected tests is not an estimate
of complete language conformance.

Windows, other compilers, upstream-wide tests, forced allocation failures and
exhaustive malformed-IR fuzzing were not run. The archive is portable source,
not a prebuilt Windows executable.

## Preservation and provenance

All 3,256 prior Fortran native-test, corpus and example source files are
byte-identical to 0.17.0. Earlier tests remain present. Two SELECT CASE corpus
expectations now recognize CHARACTER declarations with named lengths and arrays;
the uninitialized array still fails at runtime. Their source programs are unchanged. The earlier CHARACTER limit diagnostic is retained
within the new length-range message, so its existing contract still passes.
See [the source-preservation audit](verification/0.18.0/source-preservation.json).
All fifteen fixture generators reproduce their delivered source and manifests;
see [generator evidence](verification/0.18.0/generator-reproduction.json).
Historical verification through [0.17.0](VERIFICATION-0.17.0.md) is retained.

FortFront remains pinned at `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
New patches 0021–0024 are retained with descriptions and attribution. Replaying
these four with zero fuzz on the exact 0.17.0 vendor tree reproduces all 457
vendored files byte for byte; see [patch replay evidence](verification/0.18.0/vendor-patch-replay.json).
The FPM path dependency, complete vendored library sources and MIT licenses remain
included. GNU Fortran is a build tool and test oracle, never an execution backend
for interpreted programs.
