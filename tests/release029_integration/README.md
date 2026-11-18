# Release 0.29 bounded composition checks

These 12 **synthetic fixtures** combine the rank-three numeric/CHARACTER
allocatable, SHAPE and split `INTENT(IN OUT)` milestones with existing optional
association, recursion, sections and rank-reduced WHERE behavior. No source body
was extracted from or substituted for `xutilities.f90`; this suite does not claim
execution of the full original utility module.

## Run

From the repository root:

```sh
python tests/release029_integration/test_runner.py
python tests/release029_integration/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
```

Either processor can be selected independently. `--only REGEX` selects cases and
`--result FILE` writes a different report (relative to this directory unless an
absolute path is supplied). The exact additions for `scripts/verify.py`, after
`exe` and `compiler` have been resolved, are:

```python
run([sys.executable, 'tests/release029_integration/test_runner.py'])
run([sys.executable, 'tests/release029_integration/run_tests.py', '--candidate', exe, '--gfortran', compiler])
```

The suite contains no external package dependencies. The runner snapshots the
candidate executable before testing, hashes the snapshot and all fixture sources,
and records processor versions, compiler flags, exit codes, stdout and stderr.
Each GNU compilation **and execution** gets a new temporary directory, so module
files and executables cannot be reused from another fixture. Candidate checks and
executions also use a fresh directory per case.

Expected values are committed literal oracles, derived from the fixture's index,
shape and assignment operations before executing the candidate. Successful GNU
runs must match these literals; candidate output must match both literals and the
GNU output. Integer tokens are compared exactly (without binary-float rounding),
real tokens allow small formatting tolerance, and CHARACTER padding has exact
line checks. Check-only stdout, successful-run stderr, unexpected exit classes,
missing rejection diagnostics and leaked output on errors fail the suite.
The 12 Python self-tests exercise these assessment boundaries.

## Coverage and independently reasoned checkpoints

- `optional_descriptor_where`: omitted OPTIONAL forwarded as omitted; a present
  unallocated descriptor is allocated at nonunit bounds, then updated on a
  second call. The continued split direction includes trailing, blank and
  comment-only lines. SHAPE is `[2,2,2]`; the first-plane sums progress from 20
  to 32 while the other plane remains 8.
- `assumed_section_copyback`: a REAL(8) allocatable with nonunit bounds is passed
  as a reversed/strided rank-three actual to an OPTIONAL assumed-shape writable
  dummy. Keyword-ordered SHAPE with KIND=8 reports `[2,2,3]`; its rank-reduced
  section has shape `[2,2]`. WHERE and section copyback produce -942, -930,
  1742 and 1730, leaving the unselected element 831 unchanged.
- `reallocation_bounds`: same-shape assignment through a split-direction
  allocatable dummy preserves destination bounds. Changed shape adopts
  whole-array source bounds; an initially unallocated section-result destination
  gets unit lower bounds. A same-shape expression assignment keeps existing
  bounds. Plane sums are 14, 12, 12 and 15.
- `character_length_reallocation`: a deferred-length rank-three allocatable
  changes length from 2 to 4 through an allocatable dummy, preserving the source
  content and adopting source bounds. Scalar broadcast retains length 4.
  OPTIONAL replacement changes the shape and length to `[1,2,2]` and 3;
  reversed-section assignment retains `end` with expression lower bounds.
- `character_assumed_section`: the fixed-length allocatable CHARACTER control
  passes a reversed rank-three actual to an OPTIONAL assumed-length writable
  dummy. SHAPE and LEN survive association, and plane copyback yields exactly
  `xy  ` while an unselected plane retains `abcd`.
- `empty_axis_shapes`: allocations with the first, second and third extent zero
  retain the other extents through assumed-shape OPTIONAL association and
  allocatable assignment: `[0,2,3]`, `[2,0,3]` and `[2,3,0]`. No elements are
  read, and omitted OPTIONAL is not inquired.
- `recursive_result_lifetime`: an allocatable REAL(8) function result survives
  assignment and recursive split-direction descriptor forwarding. Three updates
  turn 1.5 into 4.5, making each two-element plane sum 9. A subsequent empty
  function result survives two recursive calls with shape `[2,1,0]`.
- `stat_descriptor_shape`: a failed double allocation with STAT leaves shape,
  bounds and data unchanged. A subsequent rank-two-plane WHERE update makes the
  plane sum 20, and deallocation succeeds.

The valid cases deliberately use rank-two-plane reductions, not unsupported
rank-three SUM. They initialize actual data before value-reading association or
assignment. They do not claim rank-four support, LOGICAL allocatables, unrestricted
allocation syntax or support for absent OPTIONAL SHAPE sources.

## Boundaries and compiler caveat

- `where_rank_three_boundary`: valid GNU source, **compile-only GNU evidence**.
  The interpreter must reject full rank-three WHERE while continuing to accept
  the rank-reduced WHERE cases above.
- `unallocated_shape_boundary`: **interpreter-only runtime safety check**.
  Calling SHAPE through an unallocated allocatable dummy is invalid Fortran;
  there is no GNU compilation or execution oracle. Candidate check must pass,
  execution must fail with exit 2, a diagnostic and no stdout.
- `conflicting_intent_boundary`: both processors must reject a continued split
  direction followed by a second conflicting INTENT attribute. Candidate failure
  must be source rejection (exit 1), not a crash or runtime failure.
- `deferred_section_compiler_caveat`: the same reversed-section program as the
  fixed-length CHARACTER control, but with a deferred-length actual.
  With GNU Fortran 14.2.0, a fresh compiled execution leaves the selected
  `a(1,1,2)` as `abcd`, while the fixed-length control correctly changes it to
  `xy  `. Removing OPTIONAL did not remove the discrepancy; passing the whole
  deferred-length array produced correct copyback. This is recorded as an
  observed GNU compiler discrepancy, not accepted as a new expected value.
  The candidate must still produce the independently reasoned correct result.
  GNU is **compile-only** for this fixture; it is not counted as a differential
  execution pass. `compiler-caveat-results.json` preserves the isolated fixed-
  versus deferred-length GNU outputs and hashes. Reproduce the probe by compiling
  each of these two sources in separate empty directories using the recorded
  `-std=f2018 -pedantic-errors -fcheck=all -O0` flags. This caveat is version-specific
  evidence and is not a statement that every GNU version behaves the same way.

## Recorded result

`results.json`: 12 candidate check/run cases passed; 8 independent GNU execution
comparisons, 2 GNU compile-only cases, 1 GNU compile rejection, and 1 explicit
GNU policy skip. `gnu-results.json` records the standalone GNU-only run.
The summary explicitly records one observed compiler discrepancy and 11 GNU
checks, of which only eight are executions. The candidate SHA-256 and precise
tool versions are in the reports, so these
results remain attributable if the build is subsequently replaced.

Existing feature-native tests already forge allocation, SHAPE and INTENT metadata
at producer/adapter/runtime boundaries. This suite adds source-level composition
rather than duplicating those malformed-IR matrices.

## Retained historical parser probe

`probes/bracket_print_boundary.f90` retains the exact initial synthetic CHARACTER
fixture, including `print '(3a)','[',a(1,1,2),']'`. It originally exposed a quoted
bracket parser boundary. The separate 0.43 punctuation-literal correction now
allows this unchanged source to check successfully. It remains outside these 12
original composition assertions and the old GNU section-copyback caveat remains
separate. `parser-boundary-results.json` records the latest check and source/app
hashes. No original fixture bytes were changed for this promotion.

```sh
/absolute/path/to/fortfront-interpreter --check tests/release029_integration/probes/bracket_print_boundary.f90
```

Historical version-specific verification reports retain the observations made
for their original releases; the current contract is in
[../../docs/PUNCTUATION-LITERALS.md](../../docs/PUNCTUATION-LITERALS.md).
