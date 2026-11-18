# Bounded PARITY reduction

`PARITY(MASK [, DIM])` accepts default-LOGICAL rank-one/rank-two expressions,
including constructors, comparisons, sections, allocatables, supported function
results and assumed-shape dummies. It is true for an odd number of true values.
Without DIM it returns one LOGICAL scalar. A scalar INTEGER(4/8) DIM selects the
reduced dimension; rank-one DIM results are scalar and rank-two DIM results are
vectors with the selected dimension removed. Standard keyword association works,
including `parity(dim=2,mask=a)`.

Empty reductions return false. A zero retained extent yields an empty vector.
All visited elements are checked for definition, with no short-circuit skipping,
and evaluation shares the existing instruction/expression budget. Array results
are prepared by the existing reduction machinery, including nested reductions
and the established function-result materialization rules. Constant expressions
and LOGICAL PARAMETER initializers use the same semantics. An explicit user
procedure named PARITY continues to shadow the intrinsic.

The initial subset is rank one/two and LOGICAL kind4, consistent with ALL/ANY.
Higher ranks, nondefault LOGICAL kinds, scalar MASK, KIND arguments, unknown or
duplicate keywords and direct OPTIONAL DIM dummies are rejected. DIM is validated
against the actual rank, including runtime DIM expressions. An absent MASK,
unallocated MASK, or referenced undefined element fails safely. This does not
change the existing behavior or result kinds of ALL, ANY or COUNT; their shared
metadata checks also explicitly reject a forged nondefault LOGICAL MASK kind.

## Unchanged original example

`tests/parity_intrinsic/demo_parity.f90` is a byte-identical copy of
`example/demo_parity.f90` from M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`. It is not a rewritten demonstration.
The suite checks its byte count and SHA-256 before execution. Both the candidate
and strict GNU Fortran run the original program; independent expected logical
results are checked before differential agreement is accepted.

## Verification

The focused suite has 34 source cases: 18 safe GNU execution comparisons,
seven compile-only boundary/runtime-policy cases, and nine GNU compile rejections.
No uninitialized, absent or unallocated runtime-negative input is executed by GNU.
Coverage includes both DIM directions, empty dimensions, reversed sections,
INTEGER8 DIM, keyword reordering, parameters, nested numeric/logical reductions,
allocatables, user shadowing, an IMPURE ELEMENTAL mask evaluated once per element,
rank/type/argument failures and the shared work budget.

Native tests independently verify three producer result descriptors and mutate
13 adapter/runtime contracts. Scope corruption is tested through ordinary program
execution because the constant evaluator intentionally has no active call frame.
The pre-existing logical-intrinsic mutation suite remains required.

Reference: [GNU PARITY documentation](https://gcc.gnu.org/onlinedocs/gfortran/PARITY.html).
