# ELEMENTAL subroutines and IMPURE ELEMENTAL procedures (0.15.0)

This stage adds scalar and lifted ELEMENTAL subroutine calls, and explicitly
IMPURE ELEMENTAL functions and subroutines. The interpreter still executes its
own typed representation in Fortran. GNU Fortran is a build tool and test oracle,
not an execution backend.

## Supported declarations and calls

ELEMENTAL subroutine dummies are scalar INTEGER, REAL(kind=4/8), or LOGICAL,
with INTENT(IN), INTENT(OUT), or INTENT(INOUT). Scalar CHARACTER(LEN=*) IN
arguments are also supported. Functions retain the existing scalar numeric or
logical result and IN-only dummy restriction, even when explicitly IMPURE.
Same-file modules, internal procedures, explicit RESULT, positional and keyword
actual arguments, and supported prefix permutations compose with these rules.

ELEMENTAL implies PURE unless IMPURE is written. PURE ELEMENTAL and SIMPLE
ELEMENTAL retain their respective call-closure checks. IMPURE cannot be combined
with PURE or SIMPLE. Duplicate prefixes are rejected. An IMPURE prefix on a
non-elemental procedure remains outside this release's source contract.

All-scalar calls execute once. If an actual is an array, the array arguments
must have the same rank and extent in each dimension. Lower bounds need not
match. Every OUT/INOUT actual must then be an array, and an elemental subroutine
array reference must have at least one OUT/INOUT dummy. Scalar IN arguments
expand. Writable actuals must be variables, elements or supported sections, not
expressions, constants, parenthesized variables or active DO variables. Types
and REAL kinds must match exactly; there is no implicit argument conversion.

Rank-one/rank-two whole arrays, reversed and strided sections, rank-reducing
sections, input array expressions and assumed-shape forwarding are supported.
These features do not add higher ranks, vector subscripts or array constructors.

```
elemental subroutine affine(x, scale, output_value)
    integer, intent(in) :: x, scale
    integer, intent(out) :: output_value
    output_value = x * scale + 1
end subroutine
```

## Writable association and definition state

The interpreter freezes actual destinations and validates all shapes before
invoking any scalar body. It checks overlap across the entire elemental
reference, not just matching pairs of scalar elements. A direct actual overlap
is rejected when either dummy is writable, including shifted/reversed sections
and a scalar input aliasing an element of an output array. Read-only aliases and
disjoint sections are allowed. Input expressions are materialized snapshots,
so `call copy_to(a+1,a)` uses the old input values.

Each element executes in a fresh scalar frame. Direct IN/INOUT bindings retain
definition flags: an undefined dummy is allowed when never read, and an INOUT
dummy may be initialized by assignment before use. OUT starts undefined for
every selected element. Returning without assigning an OUT dummy leaves that
actual element undefined; a later read is diagnosed. Unselected array elements
retain their previous values and flags. Local variables do not carry their
values or definition flags into the next element.

The new subroutine path snapshots actuals before execution and copies writable
values/flags back after all scalar invocations succeed. A runtime failure can
leave earlier completed PRINT records visible, but does not commit the current
elemental call's pending caller writes. This atomic copy-back is the prototype's
safety policy, not a general Fortran transaction guarantee.

## Impure evaluation and output

IMPURE ELEMENTAL bodies may PRINT and call supported impure subroutines.
Element invocations follow array element order: the first dimension varies
fastest, with a section's own element order respected even for negative strides.
Pure calls use the same deterministic order, though their pure semantics do not
make that ordering externally observable.

An impure array-valued function expression is materialized and cached once per
expression occurrence per executed statement. Its elements are not called again
when a reduction or MATMUL revisits them. A new statement execution, including a
new DO iteration, gets a fresh cache. Scalar expansion calls a scalar function
once. Nested array expressions are materialized before the enclosing reference.

PRINT still evaluates its items before writing its own record. If an evaluated
function attempts PRINT while that outer PRINT is in progress, directly or
through a subroutine, execution is rejected before the nested record is written.
Use assignment followed by PRINT to observe an I/O-producing function. An impure
function that performs no I/O on the executed path can be used in PRINT.

Fortran allows some expression evaluation to be omitted or interleaved. The
prototype's deterministic full materialization is deliberately more specific:
GNU 14 interleaves nested elemental function references, and evaluates only
selected function elements in a masked reduction. Tests record these examples
as compiler-compilation checks plus independent interpreter policy expectations,
not identical compiler-output claims. Shape inquiries retain the existing
shape-only policy and need not execute function bodies.

## Empty calls and resource limits

A zero-sized elemental reference executes no scalar bodies and reads no scalar
data actuals. Shapes and section descriptors are still validated, including a
zero stride. Such a call does not invalidate any OUT elements. A scalar function
expanded into assignment to an empty array still executes once, following the
existing scalar-expansion policy.

Every invocation, argument copy, alias check and executed body shares the
caller's work budget. Existing array/temporary storage caps, recursion rejection,
checked arithmetic, bounds checks and uninitialized-read diagnostics remain.
Compiler checks validate the full source before any output; runtime errors may
preserve records from earlier completed operations.

## Standards basis and oracle limits

The primary language reference is
[J3/23-007r1, draft Fortran 2023](https://j3-fortran.org/doc/year/23/23-007r1.pdf),
sections 15.5.2.14, 15.5.4 and 15.9. Sections 15.8 and 15.5.4 of the
[Fortran 2018 interpretation document](https://j3-fortran.org/doc/year/18/18-007r1.pdf)
provide the earlier elemental rules. [NAG's Fortran 2008 overview](https://support.nag.com/nagware/np/r72_doc/nag_f2008.html)
also describes ordered impure elemental execution.

GNU 14 accepts IN-only array subroutine calls and duplicate IMPURE even with
`-std=f2018 -pedantic-errors`; the interpreter rejects them using its independent
source checks. GNU output from overlapping or undefined-value programs is not
used as a conformance oracle. SIMPLE-to-PURE references test only weakened
inherited semantics, because the available GNU compiler lacks native SIMPLE.

Writable IMPURE ELEMENTAL function dummies are legal Fortran but remain
unsupported here. Mutable module/host data, SAVE, external file I/O, optional array/CHARACTER/derived-type or
VALUE dummies, pointer/allocatable dummies, array/character results and other
unlisted constructs remain unsupported. This is a tested subset, not a full
Fortran implementation or a production security sandbox.

See `tests/elemental_subroutines_independent`, native adapter/runtime/producer
regressions, and `examples/elemental_subroutines.f90`. The producer correction is
retained in `vendor/patches/0012-elemental-subroutine-calls.patch`.
