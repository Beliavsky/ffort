# Named generic result metadata

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. Its copyright and MIT license
remain in `vendor/fortfront/LICENSE`. This is a local interpreter correction.

The resolved-type producer treated a named generic interface as a concrete
function declaration and fell back to inferred occurrence metadata. A generic
with INTEGER and REAL64 ELEMENTAL specifics therefore lost the selected
REAL64 result kind for `twice(x**2)`, despite the correct type of the actual
array expression. The adapter rejected this disagreement.

Patch 0024 selects one exact function specific from the visible interface at
each call occurrence. Candidate names are resolved in the interface's host
scope; argument expressions and dummy declarations supply exact type/kind/rank.
Positional/keyword association is checked per candidate. Exact rank matches
precede ELEMENTAL scalar lifting. An ambiguous or unmatched generic leaves
resolved metadata unavailable instead of guessing. The selected function's
result metadata is copied, with the actual array rank for an ELEMENTAL call.
Nested calls reuse the existing bounded visiting-state resolver.

This is a metadata correction, not full Fortran generic semantic validation.
The interpreter still independently validates declarations, visibility,
association, exact selection, purity and actual shape through its recognizer
and adapter. Existing adapter type/kind/rank checks remain enabled.

`test_generic_result_producer.f90` inspects the raw producer's REAL64 array,
INTEGER array and REAL64 scalar keyword call results, then runs the unchanged
source through the independent adapter. Differential regressions also cover
ELEMENTAL specifics whose result type differs from the input, including scalar,
array and nested calls.
