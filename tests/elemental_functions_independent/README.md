# Independent pure ELEMENTAL function verification

This is a reproducible black-box CLI corpus. It imports no interpreter modules.
Expected output is specified independently in the fixture generator. GNU Fortran
is a differential oracle, never the interpreter's execution backend.

## Run

After building the interpreter:

```sh
python3 tests/elemental_functions_independent/test_runner.py
python3 tests/elemental_functions_independent/run_tests.py \
  --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

`generate_cases.py` deterministically regenerates the checked-in sources,
manifest and weakened PURE references. The runner invokes argument arrays
without a shell, uses a fresh temporary directory for each compiler invocation,
and imposes a 15-second process timeout. `--only REGEX` selects individual cases.

## Scope

The 135-case corpus has 85 successes, 30 invalid sources, nine valid but
unsupported programs, and 11 runtime-policy checks. It covers
scalar/rank-one/rank-two calls, all typed
PURE/ELEMENTAL and SIMPLE/ELEMENTAL prefix permutations, implicit purity,
explicit result names, no-argument scalar calls, scalar expansion,
nondefault lower bounds, six keyword permutations, noncontiguous/reversed and
rank-reduced sections, nested calls, reductions, result-shape inquiries, same-named
module procedures and private helpers, overlapping array assignment, empty shapes,
integer/real32/real64/logical results, mixed dummy kinds, PURE/SIMPLE call restrictions, invalid
headers and declarations, wrong shapes and argument association, and documented
subset boundaries. Composition checks pass elemental results to SUM(DIM=),
MATMUL, DOT_PRODUCT and ordinary assumed-shape IN procedures, and pass
SUM(DIM=)/MATMUL results into elemental calls. Module wrappers exercise
INT(REAL(xx)) and MAX(xx,0) operands with scoped procedure resolution.

Runtime-policy checks cover undefined scalar results and inputs, atomic PRINT,
ERROR STOP, division by zero, dynamic extent mismatch (including empty arrays),
and shared/nested execution budgets. Static failures must exit 1 before any
program output. Runtime cases must pass `--check`, then exit 2 and emit only
specified earlier records. Success must exit 0 without diagnostics and match
all expected values. Integers are exact; real64 cases use tight explicit
tolerances. No partial PRINT record is accepted.

The 15 harness self-tests check fixture regeneration, source/reference identity,
category separation, reference preservation of an identifier named `simple`,
integer and finite-value comparison, real64 tolerances, token counts, status
codes, diagnostics, and prevention of source-path diagnostic spoofing.

## Oracle limits

The checked GNU Fortran 14.2.0 toolchain does not implement SIMPLE procedures.
Both a valid SIMPLE probe and an invalid SIMPLE-to-PURE call probe are recorded.
A native SIMPLE oracle is used only if the compiler accepts the former and
rejects the latter. Otherwise SIMPLE headers are lowered to PURE while leaving
ELEMENTAL, bodies, identifiers and all actual arguments unchanged. These
references validate ordinary calculations and inherited PURE constraints only;
they do not independently validate the extra SIMPLE restrictions.

Legal unsupported programs are separated from invalid Fortran. Undefined-data,
arithmetic-safety and budget cases are interpreter-policy checks and skip the
compiler oracle. Runtime-shape and ERROR STOP cases use compile-only GNU
baselines; compiler runtime output is not treated as the interpreter's atomic
PRINT contract. `gnu-baseline-results.json` records compiler-only evidence;
`results.json` records actual candidate comparisons. JSON results contain
process output/status, tool versions, timestamps and executable/source hashes.
Passing this selected corpus does not establish whole-language conformance.
