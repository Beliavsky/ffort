# Release 0.30 bounded composition checks

These 12 **synthetic fixtures** combine the LOGICAL allocatable, scalar CHARACTER
array-element LEN specification expression, optional declaration-separator and
FINDLOC milestones with previously supported SHAPE, explicit recursion,
allocatable results, OPTIONAL forwarding, section expressions and rank-reduced
WHERE. Every source is labeled synthetic. No original utility body was changed,
extracted or substituted by this suite, and these results do not claim execution
of the full original `xutilities.f90`.

## Run

From the repository root:

```sh
python tests/release030_integration/test_runner.py
python tests/release030_integration/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
fpm test --profile debug --target test_release030_composition
```

Either processor can be selected independently. `--only REGEX` selects fixtures;
`--result FILE` changes the report path, relative to this directory unless it is
absolute. GNU-only evidence can be refreshed with:

```sh
python tests/release030_integration/run_tests.py \
  --gfortran /absolute/path/to/gfortran --result gnu-results.json
```

The exact additions for `scripts/verify.py`, after `exe` and `compiler` have been
resolved, are:

```python
run([sys.executable, 'tests/release030_integration/test_runner.py'])
run([sys.executable, 'tests/release030_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
```

The ordinary `fpm test --profile debug` aggregate discovers the new native test
through the repository's `auto-tests = true` setting. This suite does not modify
any aggregate script.

## Independent oracles and isolation

`manifest.json` contains literal expected outputs reasoned from shapes, indices,
column-major traversal and assignments before running either processor. GNU and
the candidate must each match these literals; executed GNU outputs must also
match the candidate. The two formatted CHARACTER lines require exact spaces.

The runner copies the candidate to a private snapshot and hashes it. Each GNU
compile and its execution use a new temporary directory, never a reused module or
executable. Candidate check/run commands use a fresh directory per fixture.
Recorded evidence includes command vectors, working directories, tool versions,
compiler flags, status/stdout/stderr, manifest/source hashes and top-level
`candidate_sha256`. Snapshot, source and manifest integrity are checked again at
the end. A changed original build does not change the snapshot being tested.

Integer comparisons retain exact precision. Finite real tolerance uses Decimal,
so very large finite numbers cannot become matching floating-point infinities.
The 14 runner self-tests cover exact wide integers, nonfinite outputs, overflow,
wrong exit classes, successful stderr, missing diagnostics, output leaks,
CHARACTER padding and a diagnostic word appearing only in a source filename.
Diagnostic matching strips the usual source/line/column prefix first.

## Eight GNU execution comparisons

1. `optional_logical_tensor_where`: omitted OPTIONAL forwarding is distinguished
   from present-unallocated and present-allocated rank-three LOGICAL descriptors.
   Allocation has bounds `(-1:0,4:5,7:8)` and SHAPE `[2,2,2]`. A plane mask updates
   a numeric matrix through rank-two WHERE, yielding sum 22. FINDLOC reports
   first/last diagonal coordinates `[1,1]`/`[2,2]`, then after inversion
   `[2,1]`/`[1,2]`. The untouched plane retains four true values.
2. `logical_reallocation_findloc`: same-shape assignment preserves lower bound
   -2; changing from three to four elements adopts source bounds 7:10.
   Allocated expression masks track shape changes. FINDLOC yields positions 2/3,
   handles a reversed section with first match 2, and returns last match 3 in
   source element order rather than declaration index 9.
3. `matrix_mask_dim`: rank-two allocated LOGICAL masks with nonunit bounds work
   with a colonless INTEGER matrix declaration, keyword-reordered FINDLOC,
   KIND=8, BACK and both DIM directions. First/last selected matches are
   `[1,1]`/`[2,2]`; DIM=1 gives `[1,2,0]`, DIM=2 with BACK gives `[1,2]`.
   Scalar false MASK yields `[0,0]`.
4. `character_result_filter`: an automatic explicit-result CHARACTER array
   declared without `::` uses `LEN(x(1))+1`. It returns length-five values with
   exact internal padding (`ab  !`, `cd  !`). An allocated LOGICAL mask selects
   first/last matches 1/3 in the CHARACTER FINDLOC comparison.
5. `empty_character_logical_shapes`: deferred-length CHARACTER and LOGICAL
   rank-three allocations have SHAPE `[0,2,1]`. The assumed-length CHARACTER
   dummy's descriptor supplies length 6 to `LEN(x(1,1,1))` despite no elements.
   The empty local result retains length 6 and size zero. Its empty rank-two
   section and allocated mask produce coordinate zeros and DIM=1 zeros.
6. `recursive_logical_result`: a LOGICAL allocatable function result survives
   assignment and three explicit recursive descriptor updates. One plane ends
   all false, the other retains two true elements, with FINDLOC results `[0,0]`
   and `[2,1]`. Replacing it with an allocated zero-size result retains SHAPE
   `[2,1,0]` and ALLOCATED true.
7. `optional_forwarded_findloc_value`: two levels forward an optional LOGICAL
   allocatable ARRAY and optional scalar VALUE. Omitted and present-unallocated
   descriptors are guarded before inquiry/search. Present true VALUE returns
   positions 2/4; present false VALUE returns 1/3. Absent VALUE is never read.
8. `stat_preserves_mask_search`: a failed double allocation with STAT preserves
   a LOGICAL matrix's bounds, shape and data. First/last locations remain
   `[1,1]`/`[2,2]`; numeric WHERE using that allocated mask sums to 22.
   Deallocation returns STAT zero and ALLOCATED false.

These cases do not add rank-three FINDLOC or reductions, general optional
intrinsic-option forwarding, unsupported implicit-result producer forms,
nondefault LOGICAL kinds or unrestricted CHARACTER specification expressions.

## Boundaries and classification

- `rank_three_findloc_boundary`: **GNU compile-only**. GNU accepts the source,
  while the candidate must reject rank-three FINDLOC with source rejection
  exit 1 and the specific supported-rank diagnostic.
- `len_section_colonless_boundary`: **GNU compile-only**. GNU accepts LEN of an
  array section in a specification expression. The candidate must preserve the
  bounded rejection even in a colonless declaration, with source rejection 1.
- `colonless_attribute_boundary`: **GNU syntax rejection**. ALLOCATABLE is an
  attribute, so omitting `::` remains invalid for both processors.
- `mask_shape_runtime_boundary`: **candidate-only safety policy**. The allocated
  LOGICAL MASK has extent 2 while ARRAY has extent 3. This invalid Fortran is
  neither compiled nor executed as a GNU oracle. Candidate check passes;
  execution fails with exit 2, the mask-conformance diagnostic and no stdout.

Compile-only, rejected and policy-skipped cases are not differential executions.
There are no accepted GNU discrepancies in this suite.

## Combined metadata test

`test/test_release030_composition.f90` uses a synthetic combined program with
colonless declarations, a rank-three LOGICAL allocation, a rank-three CHARACTER
LEN element in an automatic declaration and a rank-reduced FINDLOC mask. The
uncorrupted program passes both independent adapter and direct runtime checks.
Twelve corruptions produce 24 required rejection checks: allocation third-axis
operand, LOGICAL kind, LEN element third subscript, out-of-range subscript ID,
length/scope metadata, MASK type/rank, VALUE rank, result extent/kind and a cyclic
FINDLOC VALUE argument. This exercises the merged metadata path without changing
core or vendor code.

`native-results.json` is explicitly **pre-clean-build standalone evidence**: a
fresh native compile/link against the then-current merged interpreter library,
including source/library SHA-256 and the 24-rejection pass. The command vector is
retained there. It is not final clean-build evidence. The final clean `fpm test`
log is authoritative; FPM reproduces the test with the command above.

## Recorded result

`results.json`: all 12 candidate check/run assertions passed; 11 GNU checks
comprise eight independent executions, two compile-only checks and one syntax
rejection. One policy case explicitly skips GNU. `gnu-results.json` preserves the
separate GNU-only run. Both reports have zero case failures and zero integrity
failures. GNU version: 14.2.0. Exact tool versions and candidate snapshot hash are
recorded in the reports rather than inferred from the current build.
