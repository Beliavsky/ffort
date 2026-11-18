# Independent explicit-shape array tests

This suite adds 179 independently specified programs to the original 226-case
scalar corpus. It tests the interpreter's explicit-shape, rank-one INTEGER,
REAL and LOGICAL extension without using the implementation to derive answers.
Original fixture source is retained. Expectations are migrated when later
releases support a formerly excluded operation; the rank-two declaration fixture
is supported in 0.9.0.

## Running

```sh
python3 tests/arrays/test_runner.py
python3 tests/arrays/run_corpus.py --candidate /absolute/path/fortfront-interpreter --gfortran /absolute/path/gfortran --results tests/arrays/results.json
```

Both `scripts/verify.sh` and `scripts/verify.py` include this suite. The runner
accepts either `--candidate` or `--gfortran` alone, `--only REGEX`, and a per-command
`--timeout`. The candidate command is split with Python `shlex`, never run through
a shell. `make_corpus.py` regenerates source fixtures and the manifest using seed
20261114. The fixture generator is independent of parser, IR and runtime code.

## Coverage

- 98 successes: default and explicit lower bounds, negative/zero/positive index
  ranges, singleton and zero extents, integer-edge bounds, arithmetic/intrinsic
  constant bounds, multiple scalar/array declarators, scalar initializers,
  case-insensitive names, semicolons/comments, element expressions and nested
  subscripts, conversions, logical operations, intrinsics, per-element updates,
  aliasing assignment targets, mixed-type storage isolation, IF, ascending,
  descending and nested DO loops, array-element DO bounds evaluated once, and
  exact per-program storage limits. These include 49 seed-fixed state-model
  programs: 25 integer, 12 exact-dyadic real and 12 logical.
- 32 runtime-safety cases: per-element initialization, independent storage,
  uninitialized indices and bounds, invalid numeric operations/conversions,
  checked index-expression overflow, lower/upper out-of-bounds reads/writes,
  zero-extent indexing, extreme indices, loop indexing, and atomic PRINT output.
- 23 semantic and 12 syntax negatives: index type and arity, scalar subscripting,
  undeclared and duplicate symbols, assignment types, invalid bounds,
  malformed shapes/subscripts and forbidden array DO variables.
- 8 legal-but-unsupported boundaries: DIMENSION attributes, array initializers,
  vector subscripts, constructors, pointers and allocation. A late unsupported operation must be
  rejected before an earlier PRINT executes.
- 6 static safety checks: per-array and aggregate storage cap, huge extent,
  and unsafe constant bounds.

The runner reuses the original independent harness's process and value comparison
routines. It additionally requires the exact expected output prefix for every
runtime failure and diagnostic fragments for relevant array-safety checks.
Ten dedicated harness self-tests show that partial/missing output, wrong failure
messages, crashes, timeouts and successful execution of a bounds violation cannot
be counted as a pass. The original 18 harness self-tests remain in place.

## Reference policy and evidence

GNU Fortran is compiled with `-std=f2018 -pedantic-errors -fcheck=all -O0`.
Successful programs are checked against expected values with integer/logical/text
exactness and the original REAL32 output tolerance. Syntax/semantic negatives
must be cleanly rejected; legal unsupported programs must compile. Twelve
out-of-bounds cases additionally require a GNU checked-runtime bounds failure.

Of 179 cases, 152 have an applicable GNU oracle. Twenty-six interpreter-specific
safety cases are skipped for the reference because Fortran does not guarantee
that safety policy. One additional valid zero-extent case with maximum positive
lower bound and minimum negative upper bound is skipped because compiler
internal dimension-size overflow is not an independent semantic oracle. This is
an explicit limitation, not a reference pass.

Each JSON run records manifest/fixture hashes, candidate binary hash, compiler
version, full commands, outputs and stage-by-stage decisions. `results.json` records the current run; historical reports are labeled
separately. This is focused regression coverage, not a general
Fortran standards-conformance or hostile-input-security claim.

The later bounded POINTER extension promotes the unchanged `pointer_array` fixture
to supported execution (`1`). It does not inspect its undefined association state.
The current manifest, rather than historical category counts above, is authoritative.

## 0.53 numeric-vector expectation migration

The unchanged `array_vector_subscript` now passes source checking and fails at
4:11 on an uninitialized gathered element, with no stdout. Its GNU oracle is
compile-only: undefined data is never executed under GNU. The manifest and
generator retain every original source byte. The generator also reproduces the
already-shipped 0.24 `allocatable_array` success; this is generator synchronization,
not a new expectation or feature change. Historical category counts above are not
current counts; the manifest is authoritative.
