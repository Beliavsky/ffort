# Local patch 0008: expression keyword argument wrappers

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. This local interpreter-project fix
retains the upstream MIT copyright/license in `vendor/fortfront/LICENSE` and
makes no claim of upstream endorsement.

The expression parser already represents named actual arguments with assignment
nodes, but did not mark those nodes as keyword arguments. CALL statements already
set that marker. Parenthesized expression arguments now receive the same marker,
so keyword labels are not treated as assignment targets or variable references,
and existing semantic inference uses the actual RHS type and rank. The marker
is not applied to ordinary assignment statements or square-bracket indexing.

`test/test_keyword_producers.f90` directly invokes the strict FortFront frontend
without the interpreter adapter. It checks reordered function keywords, intrinsic
keywords, and CALL keywords; scalar INTEGER/REAL and whole-array REAL RHS type and
rank; and that ordinary assignments retain their non-keyword classification.
A negative function-call case also verifies that INTEGER actuals supplied to REAL
dummies still produce the strict type-mismatch diagnostic.
This is a producer correction, not an adapter workaround or diagnostic bypass.
