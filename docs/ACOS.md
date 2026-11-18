# Bounded real ACOS

ACOS(X) supports finite REAL(4) and REAL(8) operands in the inclusive range
[-1,1], returning radians in the same kind. X may be scalar or a rank-one,
rank-two or rank-three array, including dynamic dummy arrays and empty arrays.
The X keyword and supported constant expressions are accepted. In particular,
a module parameter of the form `real(dp), parameter :: pi = acos(-1.0_dp)` is
supported when dp selects the existing REAL8 kind.

INTEGER, LOGICAL, CHARACTER, complex and REAL16 operands remain unsupported.
Evaluated out-of-domain and nonfinite operands are diagnosed before calling the
host intrinsic. No unsupported IEEE value is produced. The implementation calls
the host ACOS at the input kind, including the endpoints and tiny inputs.

The recognizer, producer adapter and runtime independently validate identity,
arity, slots, type, kind and shape. Runtime validation also checks literal caches,
declared symbol metadata and the entire unevaluated expression tree with shared
cycle marks. KIND and empty arrays do not evaluate unused data. Names remain
nonreserved, with scalar, array, result-variable, procedure and generic shadows
tested. The producer metadata extension is documented by vendor patch0072.

## Verification and example scope

The focused suite has 28 source fixtures: 17 strict GNU executions, four GNU
compile-only cases and seven GNU rejections. It covers constants, endpoints,
kinds, ranks, keywords, OPTIONAL inquiries, empty arrays, shadows and domain
failures. Two native programs add 623 runtime/adapter assertions and eight
independent producer cases. Eighteen runner self-tests retain exact Decimal and
signed-zero distinctions and reject bad outcomes. Existing broad 0.39 behavior
is not claimed revalidated solely by these focused checks.

The user's original xmix_dt.f90 remains unmodified. Its full original and the
minimal variant enabling the commented ACOS parameter are validated separately
by the mixture-program harness. ACOS support alone does not resolve the other
REAL(...,KIND), multiple-ALLOCATE and RANDOM_SEED dependencies, nor change the
execution budget. This feature does not claim complete complex ACOS support or
that the full upstream M_intrinsics ACOS demonstration is supported.

Primary intrinsic description: https://gcc.gnu.org/onlinedocs/gfortran/ACOS.html.

The runner also enforces one existing ACOS registry identity, unique intrinsic
names, and agreement between the declared registry size and literal entries.
