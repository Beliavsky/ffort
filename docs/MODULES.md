# Historical 0.6.0 module-function design

This document records the original module-function increment. For the expanded
0.10.0 contract, including internal/module subroutines, numerical kinds and array
dummy arguments, see [NUMERICAL-PROCEDURES.md](NUMERICAL-PROCEDURES.md),
[ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md) and the current README.
For 0.20 module dependencies and OPTIONAL arguments, see
[MODULE-USE.md](MODULE-USE.md) and [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).

# Scalar module functions (0.6.0)

The source file may contain up to 16 modules, followed by one explicit or implicit main program. Modules must precede the main. Each module contains functions only, with an optional IMPLICIT NONE followed by CONTAINS. No separately compiled .mod files are read.

```fortran
module m
implicit none
contains
function twice(x) result(y)
real, intent(in) :: x
real :: y
y = 2*x
end function twice
end module m

program main
use m
implicit none
print*,twice(2.3)
end program main
```

This exact requested example is also `examples/module_functions.f90`. It prints a real value approximately 4.6. Real32 decimal formatting is deterministic but not byte-identical to a compiler's list-directed output.

## Accepted declarations and calls

- Plain `use m` in the main imports its functions. USE statements precede IMPLICIT NONE and declarations. Referencing an unimported function fails. Duplicate USE statements are explicitly unsupported. Two visible functions with the same referenced name are ambiguous and fail.
- Each function has an unprefixed `function f(a, b) result(r)` header and `end function [f]`. Every argument and result requires an explicit default INTEGER, REAL or LOGICAL scalar declaration. The result name differs from the function and argument names. Zero arguments use empty parentheses.
- Every argument has INTENT(IN), with no other attributes. Exactly the declared number of positional arguments is required. Argument types must match; an INTEGER actual cannot satisfy REAL, even though an INTEGER expression can be assigned to a REAL variable. Nondefault kinds, array values and sections are rejected. An array element is a valid scalar actual.
- The function sees its own arguments, result, scalar/explicit-shape array locals and local scalar PARAMETER constants, plus all sibling functions in its module, including later definitions. Main variables and names from other modules are not visible. Local declarations cannot collide with a visible function name in this subset.
- Supported function statements include scalar/whole-array assignment, block IF/ELSE and bounded counted, bare and conditional DO; see [DO-WHILE.md](DO-WHILE.md). Existing effect restrictions remain. Function calls work within those statements, arithmetic, intrinsics, main array indices/triplets and PRINT. Main array expressions may combine a scalar call with rank-one/rank-two data under the existing scalar-expansion rules.

## Call frames and safety

Every invocation has fresh argument, local and result slots. Actual arguments are evaluated in the caller before the frame starts; values are copied without aliasing. Dummy writes, including use as a DO control variable, are rejected. Uninitialized result or local reads fail at runtime with status 2. Numeric result assignment uses the ordinary checked assignment conversions.

The complete call graph is checked, including unused functions. Explicitly designated bounded recursion is now supported; see [RECURSION.md](RECURSION.md). Runtime callers retain a checked depth limit and reject reentry without RECURSIVE. All calls and their expression/statement work charge the original run's single budget; nested calls cannot reset it.

Functions cannot print, read, write, invoke subroutines or change module state. A PRINT evaluates all arguments before writing, so a failing function inside a PRINT does not emit a partial record. Output from earlier successful PRINT statements may remain. Empty array expressions retain the documented policy of not evaluating scalar data subexpressions; scalar expansion into an empty assignment still evaluates its scalar.

Mutable declaration initializers in functions are rejected because standard Fortran gives those variables implicit SAVE lifetime. They are not silently reinitialized on every call. Local scalar PARAMETER declarations with constant initializers are accepted; module functions are not allowed in constant expressions.

## Explicitly unsupported

This document records the original narrow module-function milestone. Later releases extend constants, access control, USE ONLY, internal procedures, subroutines, scalar/array arguments and supported procedure prefixes. The current contract is in the root README; named module generics are documented in [GENERIC-PROCEDURES.md](GENERIC-PROCEDURES.md). Mutable module state is now covered by [MUTABLE-MODULES.md](MUTABLE-MODULES.md). nonintrinsic module USE renaming, external procedures and SAVE attributes remain unsupported. Scalar OPTIONAL arguments and PRESENT are documented in [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).

The existing source/token/symbol/expression/instruction limits apply across the complete file, not separately per function. Additional limits are 16 modules, 1,024 procedures, 16 arguments per procedure and 64 active call frames. Whole-source metadata capacities are documented in [METADATA-LIMITS.md](METADATA-LIMITS.md). No separate compiler execution backend is used.

## Independent checks

The bounded recognizer creates typed procedure signatures and scoped instruction/expression ownership. The adapter separately examines the original FortFront multiunit AST, resolves declarations in each enclosing scope, and checks module/function identities, USE associations, dummy order and intent, RESULT identity, calls and their argument types/ranks. Native mutation tests exercise disagreements; the independent corpus compares supported programs with separately stated expectations and GNU Fortran.

Non-ELEMENTAL module procedures can contain one level of bounded internal
procedures. Their names are visible only to the host and its internal siblings,
are never exported by USE or PUBLIC, and may shadow module procedure names.
Supported host data retain their exact live activation. The original rule for
main-program internal procedures remains unchanged: mutable main host data
are excluded. See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md).

Explicit intrinsic ISO_FORTRAN_ENV ONLY aliases are documented separately in
[ISO-FORTRAN-ENV-ALIASES.md](ISO-FORTRAN-ENV-ALIASES.md); ordinary module renaming remains unsupported.
