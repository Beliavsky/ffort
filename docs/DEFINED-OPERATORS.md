# User-defined operators

The existing derived-type intrinsic-symbol overloads now also support named
operators such as `.in.`, `.notall.`, and `.twice.`. Define their specific
procedures in a same-file module's `interface operator(.name.)` block and import
with ordinary USE or `use ..., only: operator(.name.)`.

## Supported contract

- Custom names contain 1–14 letters, case-insensitively. This is an explicit
  bound from the retained producer's 16-character operator storage; longer
  names are rejected, never silently truncated. Intrinsic dotted operators and
  logical literal names are not treated as custom names.
- Unary and binary forms share an interface and are selected by arity, exact
  type, INTEGER/REAL kind and rank. Every specific is a function with required
  INTENT(IN) dummies. The existing module procedure/type restrictions apply.
- Scalars and rank-one/rank-two actuals, including assumed-shape dummy arrays.
  An exact rank match takes priority over ELEMENTAL scalar lifting. No numeric
  conversion is inserted. Ambiguous signatures are rejected even if unused.
- ELEMENTAL scalar-result functions produce array results when lifted, using
  the existing shape, empty-array, purity, recursion and evaluation-budget checks.
- PRIVATE specifics may be exposed through a PUBLIC operator. Module-private
  operators remain usable inside their own module. Main-program internal
  procedures inherit the host's USE association.
- Multiple `module procedure` lines, optional `::`, and an optional matching
  `end interface operator(.name.)` suffix.
- Defined binary operators have lower precedence than all intrinsic operators
  and associate left to right. Defined unary operators bind more tightly than
  exponentiation; parentheses delimit a compound operand.

Binary intrinsic-symbol overloads retain their derived-operand requirement,
except that binary `+` also admits a CHARACTER operand as documented in
[CHARACTER-PLUS.md](CHARACTER-PLUS.md). This does not implement intrinsic
signature overrides, defined assignment, type-bound generic operators, imported
interface renaming, OPTIONAL operator operands, or non-elemental array-valued
functions. Existing unsupported general procedure forms remain unsupported.

## Independent checks

The recognizer resolves the selected function and records an ordinary user
call with the operator spelling. The adapter independently matches the source
operator AST, interface ownership/visibility, specific list, exact operand
signature, unique selection and result type/kind/rank before execution. The
runtime invokes the existing function evaluator, not a system compiler.

Retained vendor patch 0027 fixes defined-binary precedence (previously the
producer used `.AND.` precedence), one-letter binary operator parsing, and
per-occurrence result metadata. The metadata resolver independently selects a
visible specific with exact type/kind/rank and ELEMENTAL rank preference, then
copies its declared result. It does not guess a result type from the operands.

## Verification

`fpm test --profile debug` includes two direct producer-result queries and
15 adapter baseline/mutation cases in `test/test_defined_operators.f90`.

Run the focused differential suite with:

```
python3 tests/defined_operators/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

Its 19 cases include nine GNU-compared successful programs and ten invalid
source rejections. Successes cover integer/REAL64 membership, unary and binary
ELEMENTAL evaluation, exact rank preference, INTEGER kind overloads, custom
operator precedence, one-letter names, USE ONLY, host association, module-private
operators and a LOGICAL operator expression used as a procedure actual.

The standalone membership and `.notall.` fixtures implement independent loops
to isolate operator support from logical-reduction support. They are not claimed
to be unchanged utility procedures. The cross-feature fixture at
`tests/defined_operators/integration/utilities_membership_original.f90` instead
contains unchanged `int_in_vec` and `notall` bodies from the supplied utilities
source (apart from newline normalization), with source lines and hashes in
`source-map.json`. It requires ANY/ALL as well as operators and is intended for
combined-feature verification. Expected output is `T F T F`.

Operator operand dummies must not be OPTIONAL, including in an unused interface.
The recognizer and adapter independently enforce this Fortran constraint.
