# Scalar derived types and month-date example

`examples/month_date.f90` preserves the user's later 213-line source byte-for-byte,
including CRLF endings. It is executed by the Fortran interpreter, not by compiling
the user's program. GNU Fortran is used only as a test oracle.

## Supported records

- Module-level `type name` or `type :: name`, optionally with PUBLIC or PRIVATE (which requires `::`), contains one to
  sixteen explicitly declared scalar INTEGER, REAL, LOGICAL or fixed-length
  default CHARACTER components. CHARACTER lengths must be constant integers
  from 0 through 65536.
  Component kind selectors follow the supported intrinsic kind rules. At most
  sixteen derived types may appear in one input.
- A module containing only types and constants may omit CONTAINS.
- `type(name) :: object` declares a scalar object in the main program or a procedure.
  Same-file module visibility and USE association determine type identity.
- TYPE dummy arguments use INTENT(IN), INTENT(OUT), or INTENT(INOUT). Functions
  can return a scalar derived object. Ordinary functions retain IN-only dummies.
- A structure constructor supplies positional values in declaration order;
  trailing omitted components must have defaults. Explicit values override
  defaults. Numeric components use normal checked assignment
  conversion, for example a REAL value may initialize an INTEGER component by
  truncation. LOGICAL components require LOGICAL values. CHARACTER assignment
  and constructor values are padded/truncated to the declared component length.
- `object%component` reads or assigns an intrinsic scalar component. The base
  object must be a scalar variable, not a function call or other expression.
- Whole-object assignment and procedure value/result association make independent
  copies. Modifying the original does not modify a previously assigned copy.
  Two types with identical component layouts remain distinct and cannot be
  assigned or associated as though they were the same type.

Each component has its own definition flag. Assigning one component does not
initialize the others. A component read checks just that component. A whole-object
expression and a function result require all components to be defined.
INTENT(OUT) restores component defaults and leaves nondefaulted components
undefined; copy-out preserves flags,
including components the callee never assigned. INTENT(INOUT) retains the incoming
component state. Writable argument aliases follow the existing checked argument
association policy. These deterministic checks are safety rules, not a claim that
undefined Fortran programs have a portable compiler output.

## Defined operators

Module `interface operator(...)` blocks can name module procedures for the
supported binary arithmetic and comparison operators. Each specific is a function
with exactly two scalar INTENT(IN) dummies, with at least one derived-type operand.
Specifics must be distinguishable by type/kind. Selection uses operand type,
kind, scope, module access and USE association; there is no implicit numeric
conversion to choose a procedure. The return type is the function result type.

The example defines addition, subtraction, and all six comparisons. Its
`date - date` and `date - integer` overloads return different types. Operators
are represented as ordinary checked procedure calls after resolution. They
share the execution budget, explicit-RECURSIVE requirement and procedure effect checks.
At most sixty-four operator interfaces and sixteen specifics per interface are
accepted. The original date-operator increment described above is extended in 0.20
with unary and user-named dotted operators, intrinsic-operand signatures and
elemental arrays. The current complete contract, precedence, arity and rank
rules are in [DEFINED-OPERATORS.md](DEFINED-OPERATORS.md).

Functions may use an explicit RESULT clause or the standard function-name result.
An ordinary function may call a non-PURE subroutine whose reachable statements do
not perform external PRINT or RANDOM_NUMBER. This admits validation subroutines
using STOP without making output-generating calls legal inside ordinary functions.
PURE and SIMPLE restrictions remain independently checked.

## Internal formatted output and normal termination

Fixed-length CHARACTER scalar function results are supported. An internal WRITE
accepts a literal, named parameter or bounded whole scalar runtime CHARACTER
format with scalar/array output items. Its target
must be writable. The format and each item are checked before execution, then all
values are evaluated and the complete record is built before the target changes.
A shorter record is blank-padded to the target length; an oversized record is a
checked runtime error, not silent truncation. Internal WRITE does not write to an
external unit, so the example's `date_string` can be used during PRINT evaluation.

The format grammar additionally accepts quoted literal text, including
case, spaces, commas and doubled-quote escapes; `Iw.m` minimum-digit editing; and
`I0` minimal-width output. Internal WRITE remains single-record; see
[FORMATTED-ARRAYS.md](FORMATTED-ARRAYS.md) for array items and PRINT reversion.
Bounded nested format groups are supported; see
[GROUPED-FORMATS.md](GROUPED-FORMATS.md). Bounded T/TL/TR positioning is
supported. Reached record advancement/reversion, multiple internal records,
IOSTAT/IOMSG outside defined-output callbacks and general file WRITE remain
unsupported. The documented stdout-only WRITE route is supported. Existing bounded
format/item and record-length limits still apply.

Ordinary STOP terminates the interpreted program, including nested calls, without
executing later statements. No-code and CHARACTER STOP return CLI status zero;
a CHARACTER message is reported to stderr with `STOP`. INTEGER STOP supports
portable process statuses zero through 255 and reports that status. Other INTEGER
statuses are checked runtime errors. STOP in PURE procedures is rejected. ERROR
STOP retains the interpreter's existing checked-error status two. Embedders can
distinguish normal STOP using diagnostic code three and the `stop_status` field;
the CLI translates that internal signal to the requested process status.

Wide INTEGER values and bounded INTEGER(4/8) counted DO controls use checked
integer arithmetic. See [INTEGER kinds](INTEGER-KINDS.md) for the current loop
contract and endpoint-overflow policy.

## Explicit exclusions

Version 0.18.0 extends this original record subset with scalar exact-type CLASS
dummies, default-PASS methods and bounded defined formatted output. See
[CLASS-TYPE-BOUND.md](CLASS-TYPE-BOUND.md) for the precise contract. The original
CLASS-based calendar example is now `examples/month_date_class.f90`.

Inheritance/EXTENDS, changing dynamic type, nested/array components,
arrays of records, pointer/allocatable components, nonconstant-length or
nondefault-kind CHARACTER components,
component accessibility attributes, parameterized types, derived PARAMETER values,
derived-object declaration initializers, keyword constructors or omissions without defaults
and user-defined assignment remain outside the subset.

## Verification

- `tests/derived_types`: record construction/conversion, copying, per-component
  definition state, OUT/INOUT, results, type identity, rejected boundaries and
  internal formatting. Successful language cases use independent GNU oracles;
  undefined-data/runtime policy cases are explicitly excluded from GNU comparison.
- `tests/derived_date_independent`: exact example and independently calculated
  month offsets, differences, rollover, range, comparisons and STOP behavior.
- `test/test_derived_frontend.f90`: independent AST/IR identity and structure
  mutation rejections.
- `test/test_derived_runtime.f90`: direct runtime definition-state, malformed IR
  and normal STOP contracts.
- `tests/integer_kinds_independent` and its native runtime test cover wide integer
  operations used for safe signed month offsets.

The FortFront adapter checks the original source's type definitions, component
bindings, interfaces, constructors, procedures, expressions, assignments, STOP
and WRITE nodes against independently built IR. Targeted producer corrections
are retained in the vendor patch series; no AST verification is skipped to make
the example run.

Attribute-free scalar component and `type(name)` object declarations may also
omit `::`. See [OPTIONAL-COLONS.md](OPTIONAL-COLONS.md).

## Current defaults and CHARACTER fields

Mixed initialized/uninitialized entity lists retain one default root and one
independent definedness state per component. Creation, nonsaved procedure locals,
function results and INTENT(OUT) apply the documented defaults; implicit SAVE is
not introduced. See [defaults](DERIVED-DEFAULTS.md),
[grouped declarations](../tests/derived_mixed/README.md), and
[CHARACTER fields](../tests/character_components/README.md).

Record-owned CHARACTER payloads use deep-copy ownership, a conservative 16 MiB
admission reservation, and separate output-staging accounting. These bounds are
not a whole-process CHARACTER heap or sandbox guarantee. Ordinary CHARACTER
buffers after extraction retain existing evaluator limits. LEN of a component
is metadata-only; direct KIND(component) remains a bounded runtime rejection.
