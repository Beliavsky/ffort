# Local patch 0004: scope-aware REAL kind checks

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. Upstream copyright and MIT license
remain in `vendor/fortfront/LICENSE`. This is a local interpreter-project fix,
not an upstream release or claim of upstream endorsement.

The strict argument checker converted `real(dp)` dummy declarations to default
REAL because it parsed only numeric selectors. Its literal checker separately
mistook any `d` in a suffix such as `_dp` or `_width` for a double exponent.
This rejected the valid Black-Scholes example with 20 false mismatches.

The patch shares the frontend's scope-aware kind resolver with strict checking
of scalar REAL dummy declarations and literal suffixes. Scalar actuals and typed
function-call results are checked against their scope-resolved declarations
rather than incomplete inference metadata, including CHARACTER actuals forwarded
from an internal procedure.
Default-real versus real64 incompatibilities are still rejected. It also resolves
ISO_FORTRAN_ENV named constants, including local import renames, when evaluating
integer parameter initializers. This prevents custom aliases such as
`integer, parameter :: wp = real64` from relying on a conventional `dp` spelling.
ISO_C_BINDING resolution is preserved through the same import helper.

Regression coverage is `test/test_named_real_kind_frontend.f90`, automatically
included by the root package's `fpm test`. It covers positive and negative strict
calls, shadowing `dp` with kind 4, suffix names containing `d`, named and numeric
kinds, double exponents, imported/renamed ISO kinds, host and module association,
declaration/function-result resolved real64 metadata, and nested typed function
actuals with positive and negative return-kind checks. The full numerical
corpus additionally exercises the unmodified Black-Scholes program.

This patch does not disable, suppress, or ignore semantic diagnostics and does
not promise full Fortran kind or constant-expression semantics. The existing
frontend type model and interpreter subset restrictions still apply.
