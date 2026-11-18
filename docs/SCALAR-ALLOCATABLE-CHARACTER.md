# Scalar allocatable CHARACTER

Default-kind scalar CHARACTER allocatables now use checked allocation descriptors
alongside the existing CHARACTER array machinery. Numeric scalar allocatables
remain unsupported. The complete upstream `demo_adjustl` executes without source
changes and agrees with GNU, including reallocating `astr` from LEN 20 to LEN 13.

## Supported operations

- Fixed-length and deferred-length (`CHARACTER(:)`) scalars in the main program,
  modules, procedure locals and function results. Supported procedure-entry
  specification lengths remain available for nondeferred local objects.
- Whole-variable intrinsic assignment allocates an unallocated target. Deferred
  length follows the complete RHS, including zero length; fixed length pads or
  truncates. RHS evaluation and conversion precede descriptor/value changes, so
  self-assignment, concatenation growth and substring shrink read the old value.
- `ALLOCATE(s)`, `ALLOCATE(CHARACTER(LEN=n)::s)`, DEALLOCATE, ALLOCATED and trailing
  STAT, with the existing restrictions on typed allocation. Scalar and array
  objects can share bounded multi-object allocation/deallocation lists. Successful
  prefixes, first failure and untouched suffixes retain the existing sequencing
  policy; failed allocation leaves the old scalar length and value intact.
- Allocatable IN/OUT/INOUT dummies and nested forwarding. OUT enters unallocated;
  successful return transfers allocation status, length, value and definition
  state. Actual and dummy must agree on deferred length. Nondeferred fixed dummy
  lengths require equality; assumed-length dummies use the actual descriptor.
- OPTIONAL allocatable dummies distinguish omitted from present-but-unallocated.
  A whole unallocated actual is absent when forwarded to a nonallocatable
  OPTIONAL dummy. KIND remains a type-only inquiry. LEN of an unallocated fixed-
  length object is valid; LEN of an unallocated deferred object is rejected.
- Ordinary scalar CHARACTER dummy association preserves the existing length and
  alias checks. An unallocated actual cannot be associated with a required
  nonallocatable dummy, including INTENT(OUT).
- Substring assignment and internal WRITE require prior allocation and never
  reallocate the target. Undefined values remain undefined across calls;
  allocation alone does not initialize a string.

Unsaved locals have independent frame lifetimes and begin unallocated on each
invocation, including recursion. Module allocations persist between calls within
one execution. A new execution of the same immutable program starts fresh,
including after an execution-budget failure. Allocatable function results return
owned scalar values, not views into expired frames.

## Bounds and exclusions

Each scalar length is at most 65,536 characters. The existing 16,777,216-byte
CHARACTER allocation pool and live storage-element cap also count allocated
scalars, including one storage element for an allocated zero-length string.
Assignment and copyout check limits before committing. These are bounded storage
policies, not a process-wide memory sandbox; staging and descriptor overhead are
separate. A cap-related STAT result is not claimed to match GNU's unlimited policy.

This extension does not add nondefault CHARACTER kinds, numeric scalar allocation,
SOURCE/MOLD/ERRMSG, typed allocation of nondeferred objects, declaration
initializers, explicit SAVE for allocatables, allocation of pointers/components,
new host-capture permissions, or specification-length allocatable scalar dummies.
Existing source grammar, purity, aliasing, nesting and lifetime restrictions
remain. Unsupported cases are rejected rather than emulated through ordinary
unallocated string storage.

## Representation and validation

The scalar value/definition flag remain in the normal scalar slots. A checked
one-element owned-storage marker records allocation status; its contents are
synchronized only at allocatable argument transfer. Zero string length does not
mean unallocated. The marker is never exposed as a rank-one source object.

The independent source adapter and runtime validate scalar declaration attributes,
all unused dimensions/bounds, deferred/fixed length state, dummy ownership and
whole-variable expression metadata. Scalar allocation instructions carry no bound
operands. Multi-object group, typed-length, statement-scope, effect and argument
alias checks are retained. Public IR mutation tests exercise these boundaries
without relying on source parsing alone.

## Verification

The focused suite contains 67 source cases: 38 GNU execution agreements, 26
compile-only checks and three GNU compile rejections. One compile-only case
asserts FortFront's resource-cap STAT policy. The unchanged upstream demo uses
exact line comparison, preserving all padding inside its brackets. The 146-check
native test covers source-adapter/runtime corruptions, fresh root execution and
reset after a budget failure. Twenty-four runner self-tests check diagnostics,
exit status, output leakage and exact comparison behavior.

`tests/allocatable_character/cases/scalar_allocatable_rejected.f90` is unchanged;
its historical manifest expectation is promoted to successful GNU execution.
The unchanged `tests/optional_character/boundary_scalar_allocatable.f90` receives
the same manifest promotion.
Other old source fixtures are unchanged. Focused and nearby-suite receipts are
separate from the integrator's complete clean release verification.
