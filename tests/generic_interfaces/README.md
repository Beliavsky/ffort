# Named module generic interfaces

These tests are independently authored Fortran programs, not a snapshot of the
interpreter's output. `manifest.json` contains explicit stdout expectations.
The GNU oracle uses `-std=f2018 -pedantic-errors -fcheck=all -O0`; every compiler
invocation runs in its own temporary directory to prevent stale module files.
GNU Fortran is a validation oracle only and is never the interpreter backend.

Run both implementations:

    python tests/generic_interfaces/run_tests.py \
      --candidate /absolute/path/to/fortfront \
      --gfortran /absolute/path/to/gfortran --result results.json

Run GNU only by omitting `--candidate`. `--only` accepts a case-name regex.
The runner checks candidate `--check` and execution separately, nonzero exits,
error diagnostics, no check stdout, and no stdout from rejected programs.
Whitespace and ordinary real formatting differences are normalized. Integer
expectations are exact; real expectations use small explicit tolerances.

`success` cases exercise exact type/kind/rank dispatch, keyword association, real32/real64 and logical/numeric dispatch,
ONLY imports, private specifics behind a public generic, nested
calls, function and subroutine generics, elemental lifting, and preference for
an exact-rank specific over an elemental scalar specific. Scalar, vector, and
matrix dispatch and generic host association from module and internal procedures
are covered. Composition cases include PURE wrappers, CHARACTER and derived-type
specifics, elemental subroutine array outputs, rank-two real expressions,
array-expression type propagation, and elemental results whose type/kind differs
from their actual arguments, including nested scalar and array calls. The corpus currently has 51 cases: 27 successes and 24 rejections.

`reject` cases with GNU baseline `reject` are invalid standard Fortran.
GNU baseline `compile` marks standard-conforming programs deliberately outside
this interpreter's supported subset: named interfaces outside modules, explicit
interface bodies, optional arguments, USE renaming, repeated same-name interface blocks, a generic sharing its name
with a specific, and merging same-name generics across module imports.
No GNU runtime/output agreement is claimed for those subset boundaries.

`gnu_results.json` records the initial independent GNU validation and source
hashes. Regenerate results after changing the corpus.
