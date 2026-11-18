# Scalar CLASS dummies, type-bound calls and defined output

The interpreter runs `examples/month_date_class.f90` unchanged. This is the
original CLASS-based calendar-month example, including both bound methods,
operator overloads, internal character formatting, `DT` output and list-directed
derived output. It is distinct from the non-CLASS example introduced in 0.17.

## Supported contract

- Same-file module types with the existing intrinsic scalar component rules.
- Scalar `CLASS(named_type)` dummy arguments with explicit INTENT. Dynamic
  values have exactly that declared type. There is no inheritance or changing
  dynamic type. CLASS locals/results and unlimited polymorphism are rejected.
- A type's CONTAINS section accepts `procedure :: name` or
  `procedure :: name => implementation`, optionally PUBLIC or PRIVATE. The
  implementation is a same-module, non-ELEMENTAL procedure. Its first dummy
  must be scalar CLASS of the declaring type. The default PASS convention is
  the only supported convention. A binding defaults to PUBLIC independently of
  the module's default accessibility.
- `object%function(arguments)` and `call object%subroutine(arguments)` on a
  scalar variable. Positional and keyword actuals use ordinary exact
  type/kind/rank checks. The receiver is supplied implicitly to the first dummy,
  so its name cannot also be supplied as a keyword. Mutable receivers use the
  existing definition-state-preserving INOUT/OUT call association. PURE cannot
  have a polymorphic INTENT(OUT) dummy, and no binding may mutate an IN receiver.
- `generic :: write(formatted) => binding` names one binding having the standard
  six arguments: CLASS(type) IN, default INTEGER IN unit, assumed-length
  CHARACTER IN iotype, assumed-shape default INTEGER IN vector, default INTEGER
  OUT iostat, and assumed-length CHARACTER INOUT iomsg.
- Parent PRINT supports scalar derived values, including constructor/function
  results, through bare `DT` descriptors or list-directed formatting. Callbacks
  receive `iotype='DT'` or `'LISTDIRECTED'`, an empty V_LIST and the interpreter's
  standard output unit number. Bare DT may have a flat repeat count.
- A callback may write a bounded literal format to its UNIT dummy, optionally
  with IOSTAT and IOMSG controls naming the corresponding callback dummies.
  Each child record appends to the active parent record. Successful child writes
  set IOSTAT to zero when that control is supplied; IOMSG is left unchanged.
  A callback without that control must assign IOSTAT itself. Nonzero or undefined
  callback IOSTAT fails the parent before its record is emitted.

## Execution and validation

Calls and callback bodies execute the interpreter's existing typed IR, not a
native compiler. Captured child writes cannot open files or select arbitrary
units. The parent record is committed only when all values and callbacks succeed;
records remain capped at 65,536 characters. Callback execution shares the ordinary
work budget and call-depth/recursion guards. PRINT from within a callback fails
as recursive output rather than bypassing capture. A direct callback invocation
that reaches child WRITE without a parent data transfer fails explicitly.

FortFront independently verifies CLASS declaration spelling, binding names,
implementations, accessibility, locations, receiver declaration/type identities,
passed arguments and child-write status controls. Pure/call-graph checks also
include defined child writes. Types with identical spellings in separate modules
retain their actual declaration identities. The adapter resolves the standard
implicit target of `procedure :: name` to `name` when the producer leaves its
optional implementation field empty.

## Outside this subset

No EXTENDS, ABSTRACT/deferred binding, SELECT TYPE, polymorphic allocation,
CLASS(*) or CLASS result/local, NOPASS or named PASS, binding-generic overloads,
FINAL, arrays/components as method receivers, arrays of derived values, generic
READ/unformatted I/O, DT tags/parameter lists, namelist I/O, arbitrary external
WRITE/file I/O, or internal derived-type data transfer is added. Existing scalar
CHARACTER internal WRITE remains supported. Child WRITE is confined to the
registered callback body and literal bounded formats. Runtime resource and
expression failures remain interpreter errors, not a general implementation of
recoverable Fortran I/O-error conditions.

`tests/class_type_bound` contains the unmodified full example and differential,
safety, signature, scope and unsupported-boundary tests. `test_class_frontend`
checks a valid fixture and 21 independent IR mutations.
