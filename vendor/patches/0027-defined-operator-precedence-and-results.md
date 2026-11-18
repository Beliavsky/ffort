# Defined-operator precedence and result metadata

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. MIT attribution remains in
`vendor/fortfront/LICENSE`. This is a local interpreter correction after patch 0025;
its files are independent of patch 0026.

Defined binary operators have the lowest expression precedence, below `.EQV.`
and `.NEQV.`. The producer incorrectly assigned `.AND.` precedence, and failed
to recognize one-letter binary names even though the unary tokenizer did.

Custom operator result metadata now resolves visible module interfaces and
selects a unique function using each operand's exact type/kind/rank, with exact
rank matches preferred to ELEMENTAL lifting. The result comes from the selected
function, not numeric promotion of operands. PRIVATE and USE ONLY are respected;
host scopes inherit associations. Unknown or ambiguous results remain unresolved.

`test/test_defined_operators.f90` inspects LOGICAL scalar membership and REAL64
ELEMENTAL rank-one producer metadata, followed by independent adapter mutation
checks. `tests/defined_operators` supplies GNU differential precedence, visibility,
kind/rank and operator-expression actual regressions. This producer fix does not
replace the interpreter's independent interface, dispatch or execution checks.
