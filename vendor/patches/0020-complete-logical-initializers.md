# Complete logical declaration initializers

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. Its copyright and MIT license
remain in `vendor/fortfront/LICENSE`. This is a local interpreter correction.

Single and multi-entity declaration parsing used `parse_comparison` for ordinary
initializers. That entry point excludes the lower-precedence logical operators,
so `.not.a.or.a` was stored as only `.not.a` while the declaration machinery
ignored the rest. The independent adapter correctly rejected this truncated AST.

Patch 0020 changes these two initializer calls to the existing
`parse_logical_eqv` entry point. This includes the full logical precedence ladder
without admitting assignment/range operators into the initializer grammar.
Complex initializer handling is unchanged. No source rewriting, diagnostic
suppression, adapter weakening or interpreter arithmetic change is introduced.

`test_logical_initializer_frontend.f90` independently inspects three raw producer
initializer roots, verifies the unchanged complete program through the adapter,
and rejects five mutations of its operator, operand, binding, cache or rank.
The fourteen CLI/GNU tests in `tests/logical_initializers` cover scalar and
array PARAMETER values, mutable initializers, multiple declarators, parentheses,
NOT/AND/OR/EQV/NEQV precedence, and malformed or mistyped/unbound tails.
