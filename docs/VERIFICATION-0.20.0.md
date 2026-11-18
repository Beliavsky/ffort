# Verification of prototype 0.20.0

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
| arrays | 179/179 | 154 | 0 | 25 |
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
| release_integration | 5/5 | 5 | 0 | 0 |
| sections | 183/183 | 168 | 0 | 15 |
| select_case | 91/91 | 88 | 0 | 3 |
| source_limits | 10/10 | 3 | 0 | 7 |
| utilities_slices | 33/33 | 31 | 0 | 2 |
| whole_arrays | 147/147 | 121 | 0 | 26 |
| **Total** | **3,541/3,541** | **3,239** | **83** | **219** |

Zero failures. Counts are logical source cases, not every process invocation.
Direct GNU checks include execution, compilation-only checks and expected compile
rejections. A compile-only check is not an execution comparison. Skips are not
GNU passes. SIMPLE-to-PURE references remain explicitly weakened comparisons.

Additional checks:

- All 63 native Fortran test programs, 17 CLI/resource contracts
  and 277 Python harness self-tests pass. Eight additional
  reference-partitioner checks pass, including nested internal-procedure preservation.
- The independent kind model checks 5,488 SELECTED_REAL_KIND
  calls in 69 generated programs. It is the supported
  REAL32/REAL64 model, not GNU's wider-kind behavior.
- Vendor patches 0026, 0027, 0029 and 0030 replay in numeric order against the
  preserved 0.19 vendor tree with fuzz zero. All 457 vendor files
  match byte for byte. The 0028 number is intentionally unused; OPTIONAL support
  required no producer patch. Earlier patches and provenance remain included.
- All 4,013 pre-existing native/corpus/example Fortran
  sources from 0.19 remain byte for byte unchanged. Obsolete rejection
  classifications were promoted to successful execution, with generators kept
  consistent. New regression cases are separate additions.
- The original 338,883-byte utilities source and its exact byte reconstruction
  pass preservation checks. Its full-file check/run modes reject at the
  accessibility-name capacity on line 26 without output; the complete utilities
  module is still outside this prototype's scope.

## New feature and integration checks

Defined operators are tested for precedence, unary/binary arity, exact kind/rank
resolution, elemental lifting, visibility and invalid interfaces. OPTIONAL
arguments are checked for missing slots, keyword mapping, PRESENT, forwarding,
undefined values, OUT/INOUT, elemental/generic/bound calls and KIND inquiries.

Control-flow checks cover every ELSE IF arm, nested/named counted DO,
EXIT/CYCLE across nesting, zero/negative strides, exact wide bounds and checked
narrowing/overflow. Full-int64-span loop cases use an independent policy result
instead of executing GNU's overflowing trip-count calculation. Control source
reject/runtime tests without a GNU compile oracle are counted as comparison skips.

Logical intrinsic checks cover ALL/ANY/COUNT DIM/KIND, zero extents, shape,
MERGE selection, DBLE, keywords, constants, undefined values and malformed IR.
Module USE checks cover direct dependencies, ONLY, visibility, scope isolation,
constants, types, procedures, generics, operators and chained declarations.

Two added release-integration programs compare with GNU: unchanged `int_in_vec`
and `notall` bodies using ANY/ALL, and a combined source retaining those operator
modules, seven OPTIONAL utility routines and the original kind/constants forms.
Its new wrapper/driver combines module imports, optional forwarding, logical
intrinsics, ELSE IF and named wide-loop transfers. Source maps distinguish the
retained source from the new harness. Producer and adapter cross-feature fixes
are covered by independent negative and mutation tests.

## Limits and interpretation

This is selected subset testing, not a full Fortran conformance suite or an
upstream FortFront suite pass. The interpreter never invokes GNU to execute a
user program; GNU is only the build tool and independent test oracle.

Optional arrays, CHARACTER/derived optionals, standalone OPTIONAL declarations,
non-elemental array results, imported-name re-export, procedure-local USE,
DO WHILE/CONCURRENT/unbounded or labeled DO, and named non-DO constructs remain
unsupported. Defined operator names have a 1–14-letter bound. Absent forwarding
is limited to user-procedure OPTIONAL dummies, not intrinsic optional slots.
MERGE evaluates both sources; logical reductions do not promise short-circuiting.
Full supplied utilities and Windows execution are not claimed as supported/tested.

Evidence: `docs/verification/0.20.0/final-summary.json`,
`clean-room-full-verification.log`, `vendor-patch-replay.json`,
`source-preservation.json`, and each suite's refreshed `results.json`.
The source archive includes all licenses, patches, test inputs and portable
Python/PowerShell/Bash verifier entry points, but no compiler or build cache.
