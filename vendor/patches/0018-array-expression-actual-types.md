# Local patch 0018: scope-resolved array expression actual types

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. Upstream copyright and MIT license
remain in `vendor/fortfront/LICENSE`. This local interpreter correction follows
patches 0001–0017; it is not represented as an upstream release.

The strict argument checker resolved direct named-kind array variables from
their declarations, but operator/intrinsic expressions fell back to provisional
inference metadata. The valid `mean(x**2)` call with a REAL64 array was therefore
rejected with the misleading “array, but dummy expects array” diagnostic.

The checker now requests the canonical scope-aware INTEGER/REAL/LOGICAL type resolver
before final whole-arena annotation. This preserves complete expression element
kind and rank, including numeric operators, intrinsics, scalar expansion and
sections. The existing strict match remains active; a genuine type/kind/rank
mismatch still produces a semantic error. INTEGER signedness is retained from
the existing strict element path; its separately resolved kind is checked
explicitly because the mono-type INTEGER tag does not encode kind width.
CHARACTER length handling continues through its existing path.

Two related producer metadata corrections are included and tested: scalar array
subscripts reduce declaration rank, while triplets/vector subscripts preserve a
dimension; and power with a REAL exponent uses numeric kind promotion rather
than unconditionally keeping the base kind. Only INTEGER exponents retain the
base REAL/COMPLEX kind. Array mismatch diagnostics now identify rank and element
type instead of printing indistinguishable “array” labels.

Regression coverage is the raw producer test `test_array_actual_producer.f90`,
the adapter mutation test `test_array_actual_frontend.f90`, and the 49 independent
CLI/GNU cases in `tests/array_expression_arguments`. The exact user source is
retained in `examples/mean_random_power.f90`. Random sequences are never compared
with GNU: finite range, deterministic moment inequalities, and interpreter-only
repeatability are tested separately. Deterministic analytic expressions are
compared with independently specified expected values in both implementations.

This patch does not remove semantic checking or change RNG/runtime semantics.
It does not imply support for language features outside the interpreter subset.

INTEGER4/8 PARAMETER array expressions, promotion, integer exponent kinds, exact
values beyond 2**53 and negative kind mismatches are covered by both producer
and independent tests. The 100000-element random expression is also exercised
under the documented default work budget.
