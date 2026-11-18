# Bounded output implied-DO lists

PRINT, supported standard-output WRITE, and scalar/array-element CHARACTER internal WRITE
accept ordered output lists such as `(a(i), i=1,n)`, `(i,a(i),i=n,1,-1)` and
`((a(i,j),i=1,n),j=1,m)`. Each body item can be a supported intrinsic scalar or
rank-one/rank-two/rank-three array expression. Array values retain Fortran
column-major element order. Derived-type items inside a loop are not admitted.
Constructor implied-DOs use separate statement-local index semantics; see [CONSTRUCTOR-IMPLIED-DO.md](CONSTRUCTOR-IMPLIED-DO.md). Input implied-DOs remain unsupported.

The control variable must be a declared local scalar INTEGER(kind=4 or 8). It
cannot be an active DO counter, dummy, OPTIONAL, PARAMETER, POINTER, ALLOCATABLE,
CLASS or intrinsic entity. Procedure SAVE counters and host-associated counters
are deliberately outside this bounded contract. Main-program initialized local
counters are allowed. Nested loops cannot reuse a counter that is still active.

Start, end and optional step are scalar INTEGER expressions. They are evaluated
once on each loop entry, in that order, and checked against the counter kind.
Omitted step is one. A zero step, undefined control, unsupported kind, or checked
integer overflow is a runtime error. The initial value is assigned even for a
zero-trip loop. A completed nonempty loop leaves the counter at its checked final
increment, matching ordinary DO semantics. Nested bounds may depend on outer
counters. Function results and expression-shape caches are refreshed per output
item and iteration; array/scalar results are not reused from an earlier iteration.

## Limits and effects

- At most 64 body objects per loop and eight nested implied-DO levels.
- At most 65,536 expanded values and 65,536 total loop-body iterations per output
  statement. The iteration bound also covers empty array-valued bodies.
- The existing 16 MiB staged CHARACTER-value limit and execution work budget
  remain in force. Existing formatted record, format-operation and list-directed
  output limits also remain unchanged.
- Every explicit new scratch/buffer allocation checks STAT. Expression cache
  invalidation visits only the current item's bounded expression graph.
- Data values are collected in source order before rendering. A failed statement
  emits no partial new standard-output record and does not commit an internal
  CHARACTER destination. Already completed earlier statements remain visible.
  Counter changes and ordinary function side effects are not rolled back: this
  is output staging, not a general state transaction.
- Existing PURE/SIMPLE, ordinary-function I/O, defined-output and recursive-I/O
  restrictions still apply. No external file/unit access is introduced.

The public IR uses an output-only `ex_output_do` node, not a value expression.
`valid_output_do` checks its bounded graph, counter, controls and neutral metadata.
The independent producer must agree on the original ordered objects, exact
counter binding, controls, optional step, source position and scope. Vendor patch
0081 repairs only missing child-parent links in the existing producer node, so
array classification and intrinsic-name shadow bindings remain strict.

## Original-program evidence

`tests/output_implied_do` contains exact CRLF extracts of the user's `join`,
`join_csv`, `join_csv_suffix` and `join_suffix` routines, with explicit module and
caller scaffolding. Their bodies are unchanged. It also retains the complete
pinned upstream M_intrinsics `demo_trim.f90` unchanged. These are individual
routine/demo executions, not a claim that the entire utility library runs.

All CHARACTER/formatted records of the original TRIM demo are byte-exact GNU
comparisons. Its fourth record contains list-directed integers, whose field
padding is processor-dependent; that one record uses exact numeric tokens.
Whitespace is not normalized in the remaining records. Other numeric comparisons
use Decimal/integer equality with explicit signed-zero and nonfinite guards, not
blanket floating-point tolerances.

Run `python tests/output_implied_do/test_runner.py` for adversarial oracle checks,
and `python tests/output_implied_do/run_tests.py --candidate PATH --gfortran gfortran`
for source-preservation, stage, output and GNU differential checks. Native tests
exercise malformed public IR, independent source disagreement, repeat execution
and direct producer parent/classification metadata.

## Element-file applicability (0.50)

The same bounded formatter applies to one whole CHARACTER array element as an
internal file. It is still a single record: reached slash advancement/reversion
is rejected rather than spilling into a neighboring element. See
[INTERNAL_WRITE_ELEMENT.md](INTERNAL_WRITE_ELEMENT.md) for evaluate-once indices,
staged commit and the retained PURE, derived-output, section and substring limits.
