# Pure ELEMENTAL functions (0.14.0)

This document describes the pure ELEMENTAL function stage introduced in 0.14.0.
Release 0.15.0 also adds ELEMENTAL subroutines and IMPURE ELEMENTAL execution; see
[ELEMENTAL-SUBROUTINES.md](ELEMENTAL-SUBROUTINES.md) for their separate contract.

## Declaration and calls

Declare scalar INTEGER, REAL(kind=4/8), or LOGICAL dummies with INTENT(IN), and a
scalar result using the existing explicit RESULT syntax. Typed headers and
separate result declarations both work. ELEMENTAL implies PURE; explicit PURE is
optional. SIMPLE ELEMENTAL is accepted and retains the stronger SIMPLE call
restriction. Supported type/PURE/SIMPLE/ELEMENTAL prefixes may appear in any
order, but each individual designation can occur only once.

```
elemental integer function affine(x, scale, shift) result(y)
    integer, intent(in) :: x, scale, shift
    y = x * scale + shift
end function
```

An all-scalar call returns a scalar. If any actual argument is an array, the
call returns an array of that argument's rank and shape. All array actuals must
have equal rank and per-dimension extents. Equal total size alone is insufficient;
lower bounds need not match. Scalar actuals expand across the result. No numeric
conversion occurs at argument association: type and REAL kind must match the
declared scalar dummy exactly. The result's element type and kind come from the
function result, not from its actual arguments.

Rank-one/rank-two whole arrays, rank-reducing and strided sections, array
expressions, nested elemental calls, positional/keyword mixtures and fully
reordered keyword calls are supported. The resulting array composes with
assignment, PRINT, inquiries, reductions, MATMUL and ordinary assumed-shape
INTENT(IN) argument association. Each function body still sees scalar dummies
and a scalar result, though it can use supported local arrays and call other
supported pure procedures.

## Evaluation and safety contract

The recognizer derives and validates the call shape independently. FortFront's
AST procedure designation, exact binding, actual association and call
resolved type/rank/kind must agree with that representation. Known shape
mismatches are compile errors. Dynamic section/assumed-shape mismatches are
checked execution errors before any result is assigned or a PRINT record is
written.

Section descriptors are frozen once per expression occurrence per statement.
Each result element executes a fresh scalar procedure frame in column-major
order, sharing the caller's work budget. Direct actuals retain definition flags,
so an unused undefined INTENT(IN) actual behaves as it does for ordinary calls;
reading it still reports an uninitialized-value error. Scalar data actuals may
be read again for each element, but cannot be changed by a supported pure body.
No side-effecting evaluation order guarantee beyond this subset is claimed.

A zero-sized array call invokes no bodies and reads no scalar data actuals.
Array shapes and section triplets are still validated. Inquiry operations may
inspect the result shape without invoking its function body, following the
existing deterministic shape-only policy. A scalar call on
the right side of assignment to an empty array is still evaluated once, as in
the existing scalar-expansion policy.

Whole-array and section assignment materialize and convert the entire result
before committing any element. Overlap such as `a(2:5)=f(a(1:4),a(1))` therefore
uses old values throughout. Existing bounds, arithmetic, initialization, active
DO-variable, recursion, frame-storage and execution-budget diagnostics remain
active.

## Deliberate limits

Array dummies and array result declarations are not allowed for these functions.
For the newly supported elemental subroutines and explicitly IMPURE ELEMENTAL
procedures, use the separate 0.15.0 contract linked above. Optional non-CHARACTER-array/derived-type dummies, VALUE, POINTER/ALLOCATABLE, procedure dummies,
character results/dummies, complex, ranks above two and other previously
unsupported features are not added. No new implicit conversion, broadcasting
between unequal ranks, mutable host association, recursion or external I/O is
introduced.

See `examples/elemental_functions.f90`, the three native ELEMENTAL tests, and
`tests/elemental_functions_independent/`. The producer changes are documented
and retained separately in `vendor/patches/0011-elemental-call-types.patch`.

The language basis is the elemental-procedure rules in section 15.9 of
[J3/24-007, Fortran 2023 interpretation document](https://j3-fortran.org/doc/year/24/24-007.pdf).
This document describes a tested supported subset, not full-language conformance.

Scalar OPTIONAL arguments and PRESENT, including forwarding and array expansion,
are described in [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).
