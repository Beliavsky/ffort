# Program-form and scalar PARAMETER regression suite

This independent acceptance suite tests the 0.3.0 source expansion and protects
existing exponentiation behavior. It never imports interpreter internals or uses
interpreter output to generate expected values.

## Run

```sh
python3 tests/program_forms/test_runner.py
python3 tests/program_forms/run_tests.py --candidate /absolute/path/fortfront-interpreter --gfortran /absolute/path/gfortran --output results.json
```

The candidate option takes an executable path, not a shell command. Paths with
spaces are supported. All subprocesses receive argument arrays without a shell;
GNU temporary binaries and paths use Python's portable file/process APIs. Windows
has not been executed. GNU is optional; without it, reference checks are not run.
The 10-second per-process timeout never counts as a valid source rejection.
Use `--only SUBSTRING` to select case names. Output paths are relative to this
directory unless an absolute path is supplied.

`run_tests.py` contains all source definitions and independently specified
expectations. It regenerates `cases/` and `manifest.json` deterministically when
run. The 20 generated arithmetic chains use Python integer arithmetic and seed
20261114; they stay inside the supported 32-bit range. Results record source
hashes, executable hash, GNU version, timestamp, commands, exit status, stdout,
stderr, checking stage, and per-case decisions. GNU is an independent reference,
not an interpreter backend.

## Coverage

There are 87 cases: 54 successful executions, 30 compile-time rejections, and
3 checked-runtime failures. They cover:

- Both original user snippets, unchanged, producing `32` and `55`.
- Headerless mains; optional IMPLICIT NONE; END and unnamed END PROGRAM; comments,
  semicolons, empty mains, and mandatory/matching final terminators.
- INTEGER, REAL, and LOGICAL scalar PARAMETER declarations, dependencies on earlier
  constants, multiple declarators, case-insensitive lookup, pure intrinsics,
  numeric conversion before later use, real32 rounding, and 20 model-based chains.
- Parameters in scalar initializers, array bounds (including zero extents), DO
  bounds, and logical conditions. Assigning a mutable copy leaves its constant
  source unchanged.
- Assignment, dead-code assignment and DO-control mutation of constants;
  duplicate/self/forward references; program-name collisions; missing values;
  incompatible types; variable/array dependencies; late declarations; invalid
  constant division and overflow. A synthetic headerless main name must not
  collide with a user's scalar or parameter named `main`.
- Explicit legal-Fortran boundaries for the reserved identifier `parameter`.
- Right-associative powers, unary-minus precedence, negative/zero/extreme integer
  exponents (including INT_MIN), representable integer boundaries, mixed REAL
  operations, and dynamic integer overflow/invalid power domains.

## Reference and checking policy

GNU Fortran uses `-std=f2018 -pedantic-errors -fcheck=all -O0`.
Of the 87 cases, 84 have reference checks: 54 execution/value checks,
26 rejection checks, and four compile-only checks confirming that implicit typing
and the identifier `parameter` (variable, constant, and program-name forms) are
legal Fortran although deliberately unsupported by this interpreter.
The three dynamic arithmetic failures are explicit safety-policy skips, never
counted as compiler passes.

Success must pass both `--check` and execution; check mode emits no output.
Static rejections must exit exactly 1 with a diagnostic and no program output
in both modes. Runtime cases must pass check mode, then exit exactly 2 with a
diagnostic and no output. Crashes and timeouts fail the suite. Integer-valued
expectations compare exactly even when printed in REAL/exponent notation;
nonintegral REAL values allow single-precision rounding. List-directed spacing
is not compared byte for byte.

The 25 harness self-tests exercise exact integers, REAL tolerance, missing/extra
output, logical values, correct/wrong failure stages, premature output, missing
diagnostics, process crashes, and timeout decoding. They test the evaluator rather
than the interpreter.

## Legacy expectation migration

The existing scalar suite retains all 226 source fixtures and names unchanged.
Only `unsupported_no_implicit_none` has a new expected outcome: success with `1`.
Its manifest and generator record why. Historical result files remain unchanged.
A regeneration check verified every existing fixture hash and the updated
manifest's deterministic output. No old failure was deleted to make a run pass.

See `REPORT.md`, `final-results.json`, `final-summary.txt`, and
`harness-selftest.txt` for the checked result. This is focused subset regression
coverage, not full-language conformance or a Windows verification claim.
