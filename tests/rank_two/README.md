# Independent rank-two array checks

This suite tests rank-two explicit-shape arrays, two scalar subscripts,
column-major storage, whole-array operations, inquiries and assumed-shape
argument association. Three former section-rejection probes now require successful
full-matrix, row and column selection in 0.10.0. GNU Fortran is an independent oracle, never the
interpreter's execution backend.

## Reproduce

After building, supply the resulting interpreter executable as one path:

```sh
python3 tests/rank_two/test_runner.py
python3 tests/rank_two/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The aggregate `python3 scripts/verify.py` includes both commands. Each compiler
fixture runs in a fresh temporary directory, with
`-std=f2018 -pedantic-errors -fcheck=all -O0`. The runner uses no shell; executable
paths containing spaces are supported. `generate_cases.py` regenerates the
checked-in fixtures and manifest. `results.json` records actual checks, expected
values, source/candidate hashes, compiler version and commands. Consult that
file for the result of a particular build; this document is a coverage statement.

## Independent expectations and boundaries

The 136 fixtures consist of:

- 74 successful interpreter programs. 72 must also execute with GNU and match
  independently specified values. The remaining two exercise documented empty
  expression-evaluation and conservative alias policies; only GNU compilation
  is used for those cases.
- 37 interpreter runtime-policy errors. They must pass `--check`, exit with
  status 2 and the intended diagnostic, and retain exactly the specified earlier
  output. GNU compilation verifies valid source syntax, not the interpreter's
  undefined-read, alias, overflow or dynamic-shape safety policy.
- 16 invalid sources rejected by both GNU and the interpreter. The interpreter
  must reject them before any program output, even when a PRINT appears first.
- 9 standard-valid but unsupported sources. GNU must compile them, while the
  interpreter must reject them before output. They include rank-three arrays,
  constructors/RESHAPE, DIMENSION attributes, inquiry vector
  results/keywords, explicit-shape/assumed-size dummies, array-valued results
  and the documented storage limit.

Python computes first-index-fastest layout and remapping expectations for a
matrix of empty, singleton, square and rectangular shapes with nonunit lower
bounds. Equal total sizes with different shapes, including `(0,3)` and `(0,2)`,
are explicitly nonconformable. Tests cover per-dimension bounds rather than
only flattened offsets, including out-of-range subscript pairs whose combined
linear offset would otherwise appear valid.

Additional coverage includes numerical/logical elemental operations, REAL32
and REAL64, scalar broadcast snapshots, inquiry without element reads, scalar
actuals from two-dimensional elements, frozen actual subscript pairs, IN/OUT/
INOUT array dummies, read-only aliases and writable-overlap rejection, nested
forwarding, definition-flag copy-back, empty arrays, fresh rank-one/rank-two
procedure locals, extreme INTEGER bounds and the 65,536-element limit. A
same-file module exercises rank-two dummies; a loop-based matrix multiply
provides a numerical acceptance example without claiming MATMUL support.

The 12 runner self-tests cover numeric tolerances, exact integer results,
nonfinite rejection, token counts, diagnostic requirements, exit codes and
stdout leakage. The native adapter mutation checks are a separate suite.
Passing these selected tests does not establish full Fortran conformance or
validation on untested operating systems.

The historical matrix_constructor_reshape source is retained unchanged and is now
a successful execution comparison against GNU Fortran in 0.22.0.
