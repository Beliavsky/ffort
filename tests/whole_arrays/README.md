# Whole-array independent corpus

This suite tests the supported rank-one whole-array extension using source text
and CLI behavior, independently of the interpreter's IR and implementation.

Run from the project root, with the built interpreter and GNU Fortran available:

```sh
python3 tests/whole_arrays/test_runner.py
python3 tests/whole_arrays/run_corpus.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

`--candidate` accepts a shell-like quoted command, parsed without executing a
shell. `--only` selects case names by regex. Both execution and `--check` are
verified. The full portable `scripts/verify.py` includes this corpus and its
runner self-tests.

`make_corpus.py` reproduces `manifest.json` and all source fixtures. Expected
outputs are independently specified or calculated by deterministic Python models
(seed 20261114), never copied from either interpreter's output. The 44 generated
models cover INTEGER, exactly representable REAL fractions, and LOGICAL state
updates. The suite reuses the existing independently self-tested scalar/array
CLI harness, including exact integer comparison, REAL tolerance, strict output
token counts, exit status/stage checks and diagnostic checks. Its additional
self-tests verify per-case work budgets and fixture integrity.

## Coverage

- INTEGER, REAL and LOGICAL scalar expansion and whole-array copy.
- Array/array and scalar/array operators in both operand orders; numeric
  conversions, precedence, comparisons, logical operators and elemental
  ABS/INT/REAL/MOD/MIN/MAX, including scalar arguments before array arguments.
- Equal extents with different lower bounds, extreme supported bounds,
  single-element arrays, zero-sized arrays and the aggregate element limit.
- Self-assignment and overlapping RHS scalar references such as `a=a+a(1)` and
  `a=a+a(a(1))`, with independently calculated old-value snapshots.
- Whole-array PRINT, mixed items, more than 64 expanded values, adjacent
  character concatenation across empty arrays, empty output records and atomic
  failure before any partial PRINT record.
- Static extent/type/rank errors, including scalar-only contexts and unreachable
  invalid branches. Vector subscripts and array constructors remain explicit
  unsupported boundaries in this legacy corpus. Original section, SIZE and
  rank-two fixtures retain their source with migrated success expectations.
- Per-element initialization, bounds failures, arithmetic/conversion safety,
  scalar evaluation for an empty assignment target, work budgets and the
  65,536-value expanded PRINT limit.

## Oracle boundaries

The GNU reference is compiled with `-std=f2018 -pedantic-errors -fcheck=all -O0`.
Successful portable programs must match the independent output oracle in both
implementations. Invalid programs must be rejected by both. Supported-language
features outside this interpreter's subset must compile under GNU but be
rejected by the interpreter before program output.

Bounds failures have a checked GNU runtime diagnostic. Uninitialized-value
checks, arithmetic safety and work limits are interpreter policy, not compiler
conformance claims. The deterministic empty-array rule is also tested as policy:
a scalar RHS is evaluated and converted even for an empty target; an empty
array expression performs no element evaluation. Those cases are explicitly
skipped for GNU rather than comparing undefined or processor-dependent behavior.

There are **147 cases**: 93 success, 25 invalid, 2 unsupported and 27 runtime.
See `REPORT.md` and the JSON records for the observed verification result.

## 0.53 numeric-vector expectation migration

The unchanged `unsupported_vector_subscript` keeps its historical name but now
checks and runs successfully. Defined duplicate indices produce the exact INTEGER
values `1 1`, independently confirmed by GNU. Only its manifest/generator
expectations change; all original Fortran bytes remain intact.
