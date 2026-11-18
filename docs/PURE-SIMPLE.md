# PURE and SIMPLE procedures (0.13.0)

This release checks the designations on the interpreter's supported same-file
module and internal-main functions and subroutines. It is not an implementation
of every Fortran 2023 procedure facility.

## Syntax and meaning

Use `pure function`, `simple function`, `pure subroutine`, or `simple subroutine`.
Scalar function headers can carry the type before or after either designation,
including `real(8) simple function f(x) result(r)`. The usual explicit RESULT
name and dummy declarations remain required. Case, continuation and semicolon
rules are unchanged. No designation means an ordinary (not declared pure)
procedure, even if inspection of its current body reveals no side effects.

SIMPLE is stronger than PURE, not an alias:

- A PURE procedure may call only PURE or SIMPLE user procedures.
- A SIMPLE procedure may call only SIMPLE user procedures. Merely PURE is not
  sufficient. This applies equally to function references and CALL statements,
  including nested expressions, unreachable branches and unused procedures.
- All supported intrinsic functions are simple. Unsupported intrinsics and
  unknown or external procedures remain errors, never assumed pure/simple.
- SIMPLE inherits all supported PURE restrictions: no PRINT or external I/O;
  no writing INTENT(IN) dummies or parameters; no SAVE, initialized mutable
  locals, or implicit persistent state. A subroutine may update its explicit
  INTENT(OUT/INOUT) dummy arguments, including supported array sections.
- Functions require INTENT(IN) data dummies. Local variables, the function
  result, scalar PARAMETER constants and supported mathematical/array operations
  are allowed. The existing initialized-value, overflow, alias, shape and work
  budget checks still apply.
- ERROR STOP remains allowed, as in Fortran 2018/2023. Ordinary STOP remains
  unsupported and is not permitted in a pure subprogram.

PURE procedures may read supported mutable module data. They cannot write it
or pass it to OUT/INOUT dummies. SIMPLE procedures reject mutable nonlocal
variable designators, including the standard's constant specification-inquiry
exception, which remains outside this subset. Mutable main-program host
association remains unsupported. Named constants remain usable by both PURE
and SIMPLE procedures. See [MUTABLE-MODULES.md](MUTABLE-MODULES.md).

`PURE SIMPLE` is redundant but accepted in either order, with the result type in
any supported position. Each individual prefix can occur at most once.
`IMPURE` on non-elemental procedures, `RECURSIVE ELEMENTAL`, `NON_RECURSIVE`, MODULE prefixes, external/abstract interface bodies,
procedure dummies/pointers, external procedures, nested
procedure definitions, COMMON, ENTRY, coarrays, VALUE, allocation and unlisted
syntax remain outside the subset. A failure for one of these does not imply
that the construct is invalid in full Fortran.

Pure ELEMENTAL functions are supported from 0.14.0 and imply PURE. SIMPLE ELEMENTAL remains SIMPLE; an ordinary ELEMENTAL callee is not sufficient for a SIMPLE caller. See [ELEMENTAL-FUNCTIONS.md](ELEMENTAL-FUNCTIONS.md).

## Independent checking

The recognizer records explicit PURE, effective purity and SIMPLE separately.
The FortFront producer retains the actual SIMPLE keyword in its AST and applies
its existing pure-body validation. The adapter independently compares prefix
metadata and checks the SIMPLE-only call restriction, as well as the existing
PURE call restrictions. A nonlocal-variable guard is also applied to SIMPLE
expression bindings. No source rewriting or compiler execution implements this
feature: execution still uses the unchanged Fortran interpreter runtime.

The small producer recognition patch does **not** claim comprehensive SIMPLE
semantics in standalone FortFront. The interpreter recognizer and adapter enforce
this release's fail-closed supported boundary.

## Primary references

The implementation follows [J3/24-007, Fortran 2023 interpretation document,
18 December 2023](https://j3-fortran.org/doc/year/24/24-007.pdf),
R1529/R1530 and C1552/C1553 (printed pages 338-339), 15.7 Pure procedures
(pages 345-347), and 15.8 Simple procedures (pages 347-348).

The earlier [WG5 N2212 feature summary, March 2023](https://wg5-fortran.org/N2201-N2250/N2212.pdf)
is helpful background, but its statement that SIMPLE excludes PURE differs
from the later draft's C1553. The later exact constraint excludes IMPURE with
PURE or SIMPLE, not redundant PURE SIMPLE. The code and tests follow that
constraint. C15115's constant specification-inquiry exception is not implemented.

See `examples/pure_simple.f90` (output `6 6 6 23`), the native adapter/producer
tests, and `tests/pure_simple_independent/`. GNU Fortran 14.2 on the recorded
machine cannot compile SIMPLE directly. The corpus distinguishes direct PURE
compiler evidence, independent expected values, and explicitly weakened
SIMPLE-to-PURE reference runs. Such reference runs check arithmetic and argument
semantics only; they are not a compiler validation of SIMPLE constraints.

From 0.15.0, ELEMENTAL subroutines and explicit IMPURE ELEMENTAL functions and
subroutines are admitted. IMPURE removes implicit PURE but cannot be combined
with PURE or SIMPLE. See [ELEMENTAL-SUBROUTINES.md](ELEMENTAL-SUBROUTINES.md)
for writable actuals, ordered execution, output and remaining limits.

Version 0.18.0 adds named module generics and scalar default-PASS type-bound
procedures. Their selected implementations retain all PURE/SIMPLE call restrictions;
PURE procedures cannot have polymorphic INTENT(OUT) dummies. See
[GENERIC-PROCEDURES.md](GENERIC-PROCEDURES.md) and [CLASS-TYPE-BOUND.md](CLASS-TYPE-BOUND.md).

## Recursive composition

Explicit RECURSIVE now composes with PURE and SIMPLE under the bounded activation
contract in [RECURSION.md](RECURSION.md). Callee purity and SIMPLE restrictions
continue to apply through direct and mutual cycles.
