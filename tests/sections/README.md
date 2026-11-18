# Independent rank-one array-section corpus

This suite tests array-section source text and CLI behavior independently of the
interpreter's parser, IR, frontend adapter, and runtime implementation.

Run from the project root:

```sh
python3 tests/sections/test_runner.py
python3 tests/sections/run_corpus.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The candidate command is parsed using shell-like quoting without invoking a shell.
Both execution and `--check` are checked. Optional `--only REGEX` selects cases.
`make_corpus.py` reproduces the manifest and all referenced source fixtures.
Output expectations are written independently or calculated by deterministic
Python models, not copied from either execution implementation. The 50 modeled
overlap cases use seed 20261115.

## Coverage

- Explicit and omitted triplet endpoints, omitted/default stride, positive and
  negative nonunit strides, singleton and zero-length sections, nonunit declared
  bounds, extreme INTEGER endpoints and minimum INTEGER stride.
- Dynamic scalar INTEGER bounds and stride, parameters, arithmetic, intrinsics,
  nested array-element expressions, and fresh descriptors on each loop iteration.
- Scalar expansion, section-to-section, section-to-whole and whole-to-section
  assignment; INTEGER, REAL, LOGICAL and numeric assignment conversion.
- Overlapping left/right shifts, reversal, interleaved writes, and old-value
  snapshots for both source elements and target triplet expressions.
- Elemental arithmetic, comparison/logical operators, supported intrinsics,
  PRINT expansion, empty records, character items and atomic record failure.
- Selected-index bounds errors, zero stride, shape mismatch, initialization,
  arithmetic/conversion failures, execution budget and expanded PRINT limit.
- Fail-closed malformed syntax and rank/type errors; vector subscripts,
  constructors remain explicit unsupported boundaries. The former rank-two
  section-rejection probe now requires a checked uninitialized read in 0.10.0.

## Important Fortran semantics

Omitted first and last triplet endpoints always use the array's lower and upper
bounds, respectively. They do **not** swap for a negative stride. For example,
`a(::-1)` is empty when `a` has bounds 1:5; reversal is `a(5:1:-1)`. Both GNU
Fortran and the independent expectations enforce this distinction.

An endpoint may lie outside the parent array if no selected index lies outside it.
For an array with bounds 1:5, `a(1:6:2)` selects 1,3,5 and is valid; an empty
section has no indices to bounds-check. A zero stride is still invalid, even for
an otherwise empty selection. An empty *parent array* does not make every section
empty: on a declared `a(5:3)`, `a(::-1)` attempts invalid selected indices and is
rejected at execution.

These expectations follow [WG5 Fortran 2018 draft N2137, section 9.5.3.3.1](https://wg5-fortran.org/N2101-N2150/N2137.pdf)
and the [Intel Fortran subscript-triplet reference](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2023-1/subscript-triplets.html).

## Oracle boundaries

GNU reference programs use `-std=f2018 -pedantic-errors -fcheck=all -O0`.
Successful programs must match the same independent output expectation in both
implementations. Invalid sources must be rejected by the compiler and by the
interpreter before any output. Supported Fortran outside the interpreter's
subset must compile with GNU and be rejected by the interpreter.

Section extents are determined dynamically, including when their source contains
literal endpoints. Therefore some compile-time GNU errors are deliberately
runtime interpreter errors; `--check` accepts their syntax and types. Dynamic
shape mismatches and bounds/zero-stride errors use checked GNU runtime oracles.

Uninitialized reads, arithmetic safety, deterministic empty-expression evaluation,
and resource limits are interpreter policy. These are explicitly skipped for GNU
rather than compared with undefined or processor-dependent behavior. Scalar
assignment evaluates its scalar RHS even for an empty target; empty array-valued
expressions do not evaluate element values, but still prepare and check shapes.

The runner reuses the existing independently self-tested scalar/array harness:
exact integer and output-token counts, REAL tolerance, exit statuses, static
fail-closed checks, diagnostics, and output preceding runtime errors. Its nine
additional self-tests cover checked-runtime reference outcomes, per-case budgets,
fixture integrity, and byte-for-byte generator reproducibility. Diagnostic checks
exclude source filenames, so names such as `zero_stride.f90` cannot satisfy a
missing error message.

There are **183 cases**: 120 success, 25 invalid, 3 unsupported and 35 runtime.
See `REPORT.md` and JSON records for observed results from the tested executable.

## 0.53 numeric-vector expectation migration

Three original fixtures now pass source checking and reach checked undefined-data
errors: `section_element_index` (5:14, selector element `a`),
`vector_subscript_remains_unsupported` (5:12, selector element `b`), and
`constructor_subscript_remains_unsupported` (5:12, gathered base element). Each
retains only the completed `7654` output prefix; the failing PRINT contributes no
partial record. Names and source bytes are unchanged. GNU compilation succeeds,
but these undefined-data programs are never executed as GNU reference oracles.
