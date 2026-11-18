# Bounded DIM, SIGN and LOG_GAMMA

DIM(X,Y) and SIGN(A,B) accept INTEGER(4), INTEGER(8), REAL(4) or REAL(8).
Both arguments must have the same type and kind. LOG_GAMMA(X) accepts REAL(4)
or REAL(8). Result type and kind match the arguments. Scalar expansion and
conformable arrays of rank1–3 use the existing elemental machinery. Positional
and standard keyword association, constant folding, and empty arrays are covered.
These names remain nonreserved; ordinary declarations and user functions shadow
them.

DIM returns the positive difference or zero. Integer subtraction is performed
only when the mathematical difference is positive, with a representability
check before subtraction. SIGN changes sign only when needed; this allows the
most-negative integer to retain its negative sign without first evaluating an
unrepresentable positive ABS. Requesting its positive magnitude fails closed.
REAL computations occur at their declared kind. SIGN preserves IEEE signed
zero on the tested GNU processor, including the original demo's -0.0 branch.

LOG_GAMMA computes log(abs(gamma(X))). It permits negative nonintegral inputs,
but rejects zero and negative integer poles before invoking the host function.
The interpreter's finite-value policy rejects nonfinite inputs and results.
Overflow cases are therefore runtime diagnostics, not native infinities. No
unsupported complex, extended-kind or legacy specific-name support is claimed.

KIND inquiries validate expression structure without evaluating argument values.
Empty elemental results likewise cannot bypass malformed type, kind, shape,
arity or slot metadata. The runtime independently validates public IR; it does
not rely solely on a successful source adapter pass.

## Original examples and independent evidence

`tests/elementary_math/cases/demo_dim.f90`, `demo_sign.f90` and
`demo_log_gamma.f90` are unchanged full files from `urbanjost/M_intrinsics`,
commit `fc14233036d910e3678d350efc24609e11475067`. Their hashes and original
paths are in `upstream.json`; `UPSTREAM-LICENSE` retains the original MIT license.
The test runner checks those hashes before running either compiler. No wrapper,
rewritten body, omitted statement or dependency substitution is used.

The 43 focused fixtures include the three originals and an independently
calculated numeric matrix. GNU executes16 valid initialized cases, compiles12
unsafe/undefined boundary cases without running them, and rejects15 sources.
One rejection is GNU's constant-folding diagnostic for invalid values nested
inside KIND; the candidate's descriptor-only inquiry is tested separately and
is not claimed to match GNU runtime execution. Compiler-only tests are not
runtime-equivalence evidence.

`test/test_elementary_math.f90` performs2960 independent adapter/runtime/KIND
assertions across all three functions and all supported argument kinds, including
16 corruptions in scalar, inquiry and empty-array contexts.
`test/test_elementary_math_producer.f90` separately checks15 producer metadata
and explicit name-binding cases. Expected outputs come from fixed mathematical
answers and Python's independent gamma-log model, never from candidate output.

References: [GNU DIM](https://gcc.gnu.org/onlinedocs/gfortran/DIM.html),
[GNU SIGN](https://gcc.gnu.org/onlinedocs/gfortran/SIGN.html), and
[GNU LOG_GAMMA](https://gcc.gnu.org/onlinedocs/gfortran/LOG_005fGAMMA.html).

## GNU 14.2.0 runtime DIM boundary

GNU 14.2.0 returns 2 for runtime INTEGER(8) `DIM(-HUGE(0_8),HUGE(0_8))`
on the tested processor at -O0 through -O3; constant folding returns the
mathematically required zero. The interpreter returns zero by checking ordering
before subtraction. The negative difference need not be represented when X is
not greater than Y. This valid-input oracle discrepancy is explicitly retained
as a compile-only reference in the release composition suite, not counted as
GNU execution agreement. Other numerical comparisons remain strict. Reproducer,
commands, outputs and source references are retained in
`verification/0.36.0/dim-gnu-boundary/`.
