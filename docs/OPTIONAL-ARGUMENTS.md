# OPTIONAL arguments and PRESENT

Scalar and rank-one/rank-two/rank-three INTEGER(kind=4/8), REAL(kind=4/8), and LOGICAL procedure dummies may
combine OPTIONAL with an explicit INTENT(IN), INTENT(OUT), or INTENT(INOUT).
Functions retain the existing INTENT(IN)-only rule. CHARACTER dummies may also
be OPTIONAL: fixed/assumed-length scalars, rank-one/rank-two/rank-three assumed-shape
arrays, and supported fixed/assumed/deferred-length allocatable arrays.
Numeric and LOGICAL rank-one/rank-two/rank-three allocatable arrays also support OPTIONAL. Derived types, scalar allocatables, rank-four and higher arrays,
and standalone OPTIONAL statements remain unsupported.

An omitted trailing actual needs no placeholder. Use keywords to omit earlier
optional arguments, for example `choose(required=3, last=7)`. Required dummies
must always be supplied. Unknown or repeated keywords, excess actuals, and a
positional actual following a keyword fail before execution. Existing exact
type/kind/rank and writable-binding requirements remain in force.

`PRESENT(a)` and `PRESENT(a=argument)` return default LOGICAL and accept only an
unparenthesized optional dummy name in the current procedure. The inquiry reads
presence, not the value or definition flag. An undefined supplied variable is
present; omitting an argument makes it absent. An INTENT(OUT) optional dummy is
present when supplied, even before its first assignment.

An absent optional dummy can be forwarded directly to another supported
user-procedure OPTIONAL dummy.
The nested callee observes it as absent. Supplying a present but undefined dummy
preserves undefinedness. Passing an absent dummy to a required dummy, using it
in an expression, reading it, or assigning to it produces a checked runtime
error. Presence state is fresh for every invocation and remains separate from
value initialization. KIND remains a type-only inquiry: it can inspect an absent
dummy, PRESENT, or a function call with omitted optionals without evaluating
the argument or function body. Parentheses turn a variable into an expression for this
purpose. A logical expression such as `present(x) .and. x > 0` is not a safe
substitute for an IF guard because this interpreter does not short-circuit it.

Except for INDEX BACK as documented below, absence forwarding into intrinsic optional argument slots is outside this
release's subset. For example, `size(a,dim=d)`, `sum(a,mask=m)`, and
`selected_real_kind(p=p)` with absent optional dummies are valid Fortran, but
this interpreter reports `absent OPTIONAL dummy referenced: <name>` when it
would evaluate that actual. Such calls pass the static check because a supplied,
present actual remains supported. Omit the intrinsic argument explicitly in an
IF/PRESENT branch instead. These are documented runtime-policy boundaries, not
errors in the original Fortran. KIND remains type-only and does not evaluate
these actual values, including in the supported nested inquiry forms.

ELEMENTAL functions and subroutines support omitted optionals and forwarding.
Only supplied array actuals determine shape; omitted optionals are absent in
each scalar invocation. Scalar supplied optionals broadcast as normal. Empty
array invocations execute no scalar bodies. Generic procedures independently
associate keywords and optional slots for each candidate, retain exact-match
preference over elemental expansion, and reject ambiguous applicable specifics.

The parser represents omitted procedure actuals as explicit zero slots in dummy
order. The FortFront adapter independently reconstructs this association from
AST actuals and cross-checks OPTIONAL declarations and dummy attributes. Runtime
frames carry separate presence flags and never allocate or copy absent values.

## Verification

`tests/optional_arguments/run_tests.py` compares supported programs with GNU
Fortran and separately checks syntax boundaries and runtime safety errors.
`exact_utility_bodies.f90` contains seven unchanged normalized routine fragments
from the supplied utilities source: default_integer, default_real,
default_logical, present_and_true, and set_optional_integer/real/logical. Their
provenance and normalized hashes are recorded in `utility_provenance.json`.
`test/test_optional_arguments.f90` independently mutates adapter and runtime IR
to ensure absent slots and PRESENT metadata fail closed.

## DIM arguments

ALL, ANY, COUNT, SUM, PRODUCT, MINVAL, MAXVAL, LBOUND and UBOUND cannot receive a
direct OPTIONAL dummy as DIM, even on a path where it is present. The source
recognizer and adapter reject these calls independently. Expressions such as
`DIM=(d)` or `DIM=d+0` remain valid when d is present. SIZE is exempt from this
language restriction. Tests are in `tests/optional_dim` and
`test/test_optional_dim.f90`.

## CHARACTER optionals

Presence is independent of allocation and definition. A supplied but undefined
CHARACTER variable remains present and LEN can inspect its length without
reading its value. Whole unallocated allocatable actuals are absent when
associated with a nonallocatable OPTIONAL dummy, but present when associated
with an allocatable OPTIONAL dummy. Direct forwarding preserves this distinction.
Absent CHARACTER dummies cannot be read, assigned, or passed to LEN; KIND remains
a type-only scalar inquiry. Use IF/PRESENT guards, not logical short-circuit
assumptions. Existing writable-binding, type, rank and CHARACTER length rules
continue to apply. Zero-length strings and empty arrays are supported.

`tests/optional_character/run_tests.py` independently checks expected output and
GNU Fortran output, compiles but does not execute unsafe absent accesses, and
retains negative tests for rank three and scalar
allocatables. The three original utility routines in `original_utilities.f90`
are byte-exact excerpts with SHA256 provenance. `test/test_optional_character.f90`
checks 60 independent adapter/runtime mutations across six scalar, array and
allocatable descriptor forms. `test/test_optional_character_forwarding.f90` adds
12 runtime rejections for forged missing/unallocated actual descriptors.
`test/test_optional_character_producer.f90` checks
12 declaration descriptors across attribute orders and single/grouped entities.
The focused CLI corpus has 34 cases: 19 GNU executions with independently
asserted output and 15 compile-only safety/boundary cases.

## Numeric and LOGICAL arrays

Assumed-shape arrays retain exact type/kind/rank matching, declared dummy lower
bounds, section association and all supported subroutine intents. INTEGER and
REAL and LOGICAL allocatable arrays also support OPTIONAL, preserving their existing bounds,
allocation and copy-out rules.
A whole unallocated intrinsic allocatable actual is absent for a nonallocatable
OPTIONAL dummy, and present for an allocatable OPTIONAL dummy. Direct forwarding
preserves absence; parentheses, elements, sections and other expressions do not.
PRESENT and KIND do not read array values. SIZE/bound inquiries require presence,
but do not require defined elements. Existing overlap rejection and definition
flags remain in force for OUT/INOUT, including nested forwarding and empty arrays.

INDEX supports direct OPTIONAL LOGICAL array BACK with the same absence/default
semantics as scalar BACK when STRING or SUBSTRING supplies the result array shape.
An absent array BACK with scalar STRING and SUBSTRING is rejected at runtime because
no present argument supplies an array shape. Other intrinsic absence-forwarding
boundaries listed above remain unchanged.

`tests/optional_numeric_arrays` checks GNU differential behavior, empty arrays,
kinds, sections, allocation, forwarding, inquiries, aliases and unchanged utility
bodies. `test/test_optional_numeric_arrays.f90` independently mutates declaration
and absent-forwarding descriptors to check adapter/runtime validation.
