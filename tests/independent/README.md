# Independent Fortran interpreter acceptance corpus

This corpus is independent of the interpreter's parser, typed representation, and
runtime. Expected results were written before executing the interpreter.
It tests a deliberately small documented subset, not whole-language conformance.

## Run

Python 3 is the only harness dependency. The candidate command must implement:

- `COMMAND source.f90`: execute the original source.
- `COMMAND --check source.f90`: check the whole source without executing it.
- Exit 0 on success, 1 on syntax/semantic/unsupported input, 2 on runtime error.

```sh
python3 run_corpus.py --candidate '/absolute/path/fortfront-interpreter'
python3 run_corpus.py --gfortran /absolute/path/gfortran --results baseline-results.json
python3 run_corpus.py --candidate '/absolute/path/fortfront-interpreter' --gfortran /absolute/path/gfortran
python3 -m unittest discover -s . -p test_runner.py -v
```

A candidate command containing spaces can be quoted, for example
`--candidate 'python3 /path/to/interpreter.py'`. No shell executes the command.
Use `--only REGEX` for a selected regression and `--timeout SECONDS` to adjust the
per-invocation time limit (default 6 seconds). Complete results include both
check-mode and execution-mode command/exit/stdout/stderr and pass/fail reasons.

## 0.3.0 expectation migration

The source and legacy name `unsupported_no_implicit_none` are unchanged. Its
current manifest expectation is now success with stdout `1`, because 0.3.0
supports explicitly declared variables without `IMPLICIT NONE`. The generator
records this one expectation change. Historical reports and result JSON files
below remain unmodified 0.1.0/0.2.0 evidence. Current counts are 140 success and
16 unsupported cases, with every other category unchanged.

## Historical coverage and independently verified baseline

The checked-in 226-case corpus contains:

- 139 successful programs, including 100 seed-fixed generated expressions (60 integer,
  40 real32; seed 20261114): scalar INTEGER/REAL/LOGICAL declarations and initializers,
  arithmetic and exponentiation precedence, integer truncating division, numeric
  conversions, default REAL single-precision rounding, logical operators and
  comparisons, block IF/ELSE, counted DO, comments, print strings, six intrinsics.
- 22 syntax failures, especially `x=(1+)`, missing operands, trailing tokens,
  unclosed constructs, and mismatched program names.
- 28 semantic failures: undeclared names, duplicates, incompatible types,
  invalid operators/conditions, nonconstant initializers, invalid loop controls,
  modifying an active DO variable, and intrinsic argument errors.
- 18 runtime-safety cases: uninitialized reads, division by zero, 32-bit integer
  overflow, real non-finite results, out-of-range conversion, zero DO step,
  terminal DO-variable overflow, and an execution budget.
- 2 static-safety checks for overflowing constant initializers.
- 17 explicit unsupported-boundary cases: arrays, kinds, CHARACTER variables,
  complex, DO WHILE, SELECT CASE, other I/O, modules, procedures, single-line IF,
  ELSE IF, missing IMPLICIT NONE, and explicitly reserved keyword/intrinsic names. One case puts PRINT before an unsupported
  statement to require rejection before any earlier execution. The multiple
  PROGRAM case is invalid Fortran rather than a legal unsupported feature.

GNU Fortran 14.2.0 was run with `-std=f2018 -pedantic-errors -fcheck=all -O0`.
All 139 successful sources compiled and their outputs matched independent oracles.
All 50 syntax/semantic negatives were rejected. All 17 unsupported classifications
were checked: 16 compile as legal Fortran and the two-main-program source is
rejected. Thus **206 baseline checks passed, zero failed**. The 18 runtime and 2 static-safety cases
are deliberately skipped for compiler comparison: the interpreter's fail-fast
safety contract is stronger than portable Fortran or GNU runtime checking, and
unsafe execution is not an independent semantic oracle. GNU even folds the constant
initializer `2147483647+1` to INT_MIN under these flags, so no compiler-rejection
claim is made for that stronger interpreter guard.

## Important semantics tested

DO start/end/step expressions are evaluated once. Zero-trip DO still defines the
control variable to the initial value. After normal termination, the control
variable has the incremented value past the terminal bound. Negative strides,
non-unit strides, nested loops, and sequential reuse are included. Assigning to
an active control variable is rejected even in unreachable code.

Syntax/semantic/unsupported failures must occur before any program stdout.
Runtime failures must pass check mode, then fail execution with a diagnostic.
Valid programs must produce the expected number and value of output tokens.
Output whitespace is ignored, except the bare PRINT regression explicitly requires
two output lines. The invalid comma-only `print *,` must be rejected. Integers, integral REAL expectations, strings,
and booleans compare exactly; other finite numeric values use default REAL
roundoff tolerance. The runner does not claim byte-for-byte Fortran list-directed
formatting equivalence. It never treats a process crash or timeout as rejection.

## Files and limits

- `make_corpus.py`: readable source of all cases and oracles; rerun to regenerate.
- `manifest.json` and `cases/`: generated inputs and contract expectations.
- `run_corpus.py`: independent process runner and stage/output evaluator.
- `test_runner.py`: 18 self-tests proving the evaluator detects wrong values,
  missing output, silent acceptance, wrong failure stage, execution before static
  rejection, missing diagnostics, and timeout.
- `baseline-results.json`, `baseline-summary.txt`: recorded GNU reference run.
- `REPORT.md`, `final-results.json`, `final-summary.txt`: authoritative integrated
  verification, 226/226 passed, plus the repeated GNU baseline. Metadata records
  source hashes, manifest hash, timestamp, and candidate binary hash.
- `initial-candidate-results.json` and `initial-candidate-summary.txt`: preserved
  pre-fix integrated run (215/220), clearly separate from final results.
- `intermediate-222-results.json` and `intermediate-222-summary.txt`: preserved
  earlier pass before the final reviewer regressions were added.
- `harness-selftest.txt`: all 18 evaluator self-tests passed.

This is a focused regression corpus, not a standards certification, fuzzing
campaign, performance benchmark, or claim that every program in the subset
behaves correctly. Diagnostics must be present, but this version does not enforce
exact wording or source-location accuracy. Generated cases and baseline results
are redistributable with the prototype; the external compiler is not included.
