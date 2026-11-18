# Procedure argument association (updated for 0.10.0)

Later bounded explicit-shape dummy support is described in
[EXPLICIT-DUMMY-BOUNDS.md](EXPLICIT-DUMMY-BOUNDS.md); it adds same-rank element-order
prefix association without relaxing the existing alias/definition checks.

## Supported interface

Subroutine scalar INTEGER, REAL(kind=4/8) and LOGICAL dummy arguments may have
INTENT(IN), INTENT(OUT) or INTENT(INOUT). Rank-one and rank-two assumed-shape dummies of these
same types are supported in functions and subroutines. Functions retain
INTENT(IN)-only arguments and scalar results. PURE subroutines may use writable
dummies. Scalar CHARACTER(LEN=*) remains INTENT(IN)-only.

Every dummy requires an explicit INTENT declaration. Types, REAL kinds and ranks
must match exactly at calls; assignment conversions do not apply to association.
Calls accept positional or keyword actual arguments, with at most 16 arguments. Procedure locals may be scalar or constant explicit-shape rank-one/rank-two arrays.
Function results remain scalar. Every invocation has fresh local storage.

```fortran
subroutine shift(values, amount, first)
    real, intent(inout) :: values(:)
    real, intent(in) :: amount
    real, intent(out) :: first
    values = values + amount
    first = values(1)
end subroutine
```

Array dummies use `x(:)`, `x(constant_lower:)` or two such dimensions,
for example `x(:,:)` and `x(-1:,3:)`. The lower bound defaults to 1;
the upper bound is lower bound plus actual extent minus one. The actual's lower
bound is not inherited; this rebasing applies independently to each dimension. The explicit dummy lower bound is a scalar INTEGER
constant expression. Assumed-size arrays, dynamic assumed-shape dummy
lower bounds, rank-four and higher arrays, standalone DIMENSION statements,
CONTIGUOUS, POINTER and VALUE are unsupported. OPTIONAL arrays follow
[OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md). Numeric allocatable dummies use
the distinct descriptor-preserving contract in [ALLOCATABLES.md](ALLOCATABLES.md). Supported numeric
and logical [array function results](ARRAY-RESULTS.md) can be read-only actuals.

## Actual arguments and definition state

An INTENT(OUT/INOUT) actual must be a writable scalar variable, scalar array
element, whole rank-one/rank-two array or rank-one/rank-two triplet section. Literals, arithmetic
expressions, PARAMETER constants, INTENT(IN) dummies and parenthesized variables
cannot be writable actuals. Active DO variables cannot be written through a
call. Writable actual addresses and section bounds are resolved in the caller
before execution, including when a later dummy changes a subscript variable.

INTENT(IN) accepts corresponding variables, elements and sections, plus scalar
and array expressions. A direct variable binding carries the actual's definition
flags without reading all its values. This allows partially initialized arrays
when the callee reads only defined elements. Expression actuals are evaluated
before the call; array expressions become element-ordered temporary values.

INTENT(OUT) makes the associated scalar or selected array elements undefined on
entry. A callee must assign before reading; an unassigned OUT dummy remains
undefined on return even if the caller's previous value was defined. Each array
element has its own flag. INTENT(INOUT) preserves incoming definition state, so
an undefined actual may be passed if it is assigned before any read. These rules
also hold across nested forwarding and RETURN.

The implementation uses bounded value-result frames and frozen caller bindings.
Writable values and their definition flags return to the selected caller slots.
Writable aliasing is rejected. Mutable main-program host data remain excluded.
For module data, direct actuals cannot also be referenced through the callee’s
transitive host/USE associations; see [MUTABLE-MODULES.md](MUTABLE-MODULES.md). If execution
fails, no normal return or continuation is attempted. Earlier printed records may
remain, as for other checked runtime failures.

## Aliasing and sections

Whole arrays, forward/reverse/strided sections and empty sections are supported.
Rank-two sections may reduce to rank one with either scalar/triplet orientation;
the actual result rank must match its dummy. See [RANK-TWO-SECTIONS.md](RANK-TWO-SECTIONS.md).
Only selected elements are copied back. Element order, not physical stride or
actual lower bound, determines dummy order. Nested sections of a dummy preserve
the final caller mapping.

If two direct actual bindings overlap and either dummy is writable, the call is
rejected before executing its body. This is a conservative, explicit safety
policy: even a call whose body happens not to access the overlapping data is
rejected. Read-only aliases are accepted, as are disjoint sections/elements of the
same array, including interleaved strides. Empty bindings overlap nothing.
Array expression temporaries do not alias the underlying input variables.

Existing section rules remain: a zero stride fails; only selected indices must
be in bounds; omitted endpoints use the declared lower/upper bounds for either
stride sign. Use `a(upper:lower:-1)` for reversal, not `a(::-1)`.

## Shape inquiries

- `size(array)` returns the total element count; `size(array, dim)` returns that dimension's extent.
- `lbound(array, dim)` and `ubound(array, dim)` return scalar INTEGER bounds.
- DIM is a scalar INTEGER expression from 1 through the array rank. KIND arguments and bound-inquiry forms without DIM are unsupported. ARRAY and
  DIM keyword arguments are supported.
- Whole array variables expose their declared bounds; assumed-shape variables
  expose their rebased dummy bounds. Sections and expression arrays have lower
  bound 1. A zero-sized dimension has inquiry bounds 1:0; nonempty dimensions retain their own bounds, even when the total size is zero.
- Inquiries resolve shape but do not read array element values. Runtime triplets
  are still checked. These inquiries are not declaration constant expressions
  in this release.

## Limits and verification

A frame may contain at most 1,000,000 array elements, including associated dummy
storage; a single call may materialize at most 1,000,000 array actual elements in
total. Copies, section resolution, alias checks, body execution and nested calls
share the existing work budget. Frame depth remains at most 64; recursive cycles require explicit RECURSIVE
on every participating procedure. See [RECURSION.md](RECURSION.md). Runtime checks cover rebound upper-bound integer
overflow, shape conformance, selected indices and undefined reads.

`examples/argument_association.f90` combines an IN array, scalar OUT results,
an INOUT array and a scalar array-element INOUT actual. Independent valid and
unsupported GNU-oracle cases and interpreter-only safety tests are under
`tests/argument_association`; exact release totals are in `VERIFICATION.md`.

## Keyword actual arguments

Release 0.12.0 associates user-procedure actuals by dummy name as well as position.
Supported scalar and rank-one/rank-two intrinsic dummies may be OPTIONAL; see [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md). Type, kind, rank and writable-binding checks are
unchanged; see [KEYWORD-ARGUMENTS.md](KEYWORD-ARGUMENTS.md).

Bounded internal procedures use the same value-result dummy rules while supported
host captures directly reference the defining activation. A direct host actual
cannot also be referenced through the callee’s transitive host associations; a
parenthesized input snapshot remains valid. Entering a recursive host creates
new local storage, which is not confused with the older activation. See
[INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md).
