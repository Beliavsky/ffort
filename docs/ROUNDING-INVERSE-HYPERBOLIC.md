# Real rounding and inverse hyperbolic functions

AINT(A[,KIND]) truncates toward zero and ANINT(A[,KIND]) rounds to the nearest
whole value, with halfway cases away from zero. Both accept finite REAL(4/8)
and return REAL of the input kind unless a supported constant scalar INTEGER
KIND expression selects 4 or 8. Supported INTEGER selector kinds are 4 and 8.
Standard A/KIND keywords, including reversed order, are supported.

Rounding occurs at the input kind before conversion to the selected result kind.
The implementation does not convert through a host INTEGER, so finite values
beyond INTEGER range remain valid. A result too large for a requested REAL(4)
is a checked runtime error. Zero signs follow the tested IEEE host model.

ASINH(X) accepts every finite REAL(4/8) value. ACOSH(X) accepts finite REAL(4/8)
values at least one. Both return X's kind and support the X keyword. Evaluation
uses the host intrinsic at the input kind, including small/subnormal and large
finite values; ACOSH(1) is zero. Nonfinite evaluated operands and ACOSH operands
below one produce diagnostics. Complex inputs, REAL(16), legacy specific names
and general IEEE nonfinite arithmetic are outside this bounded extension.

All four operations are elemental at ranks 0 through 3, including array
expressions, dynamic dummy arrays and zero-sized arrays. Their names remain
nonreserved: declared scalar, array, result, procedure and generic shadows are
covered. Existing source/runtime resource limits remain unchanged.

## Structural validation

The recognizer, public producer adapter and runtime independently check call
identity, operand/result type and kind, arity, slots and result shape. AINT and
ANINT additionally validate constant KIND metadata and select result kind from
it rather than the first written actual argument. The vendor producer resolves
keyword A and KIND explicitly. It does not reserve the four intrinsic names.

The runtime walks the entire operand metadata tree, including unary inputs whose
kind might otherwise be hidden by a selected result kind. Shared cycle marks
reject direct and indirect cycles. Literal caches and declared symbol kinds are
checked against expression metadata. KIND inquiries and empty-array execution
validate structure without evaluating unused data values, including undefined
or absent OPTIONAL data. No invalid domain evaluation is performed merely to
answer KIND.

## Complete original examples

Four complete unchanged files from urbanjost/M_intrinsics commit
fc14233036d910e3678d350efc24609e11475067 pass both checking and execution:

- demo_aint.f90
- demo_anint.f90
- demo_asinh.f90
- demo_acosh.f90

The files retain upstream bytes and their original declarations, imports,
comments and displayed computations. Provenance hashes and the upstream MIT
license are in tests/rounding_inverse_hyperbolic/. Expected outputs are compared
rather than merely accepting successful exits. No whole-repository completeness
claim is made.

## Evidence and GNU limitation

The focused suite contains 66 source cases: 24 GNU executions, 14 compile-only
cases and 28 GNU rejections. It covers all four originals, ranks and kinds,
keywords, source errors, runtime domain/overflow errors, empty/inquiry behavior,
shadows and 208 independently reconstructed exact rounding values. Two native
programs add 3,012 independent adapter/runtime assertions and 22 producer cases.
Fifteen harness self-tests reject false success, output leaks, nonfinite values,
signed-zero mismatches and adjacent decimal values that binary64 would coalesce.
Exact checks use Decimal tokens without binary floating-point conversion.
Nonzero tolerances are scoped to displayed approximate numerical results.
Independent zero-valued rounding expectations retain the input sign according
to this tested IEEE host contract, without changing any Fortran source.

GNU 14.2 runtime optional-KIND narrowing differs from its constant folding for
valid finite inputs immediately below rounding boundaries. AINT(1.999999999999d0,4)
returns 2 at runtime versus 1 when constant folded; ANINT(0.499999999999d0,4)
returns 1 versus 0. Explicit round-then-assign and independent arithmetic agree
with the interpreter's 1 and 0. Both final values are exactly representable.
The isolated runtime boundary is GNU compile-only, never mislabeled as an
execution agreement. Ordinary cases retain strict differential checks. The
source, -O0/-O2 flags, compiler version and outputs are preserved under
oracle-limitations/; no compiler-source explanation is asserted.

Primary intrinsic descriptions: https://gcc.gnu.org/onlinedocs/gfortran/AINT.html,
https://gcc.gnu.org/onlinedocs/gfortran/ANINT.html,
https://gcc.gnu.org/onlinedocs/gfortran/ASINH.html and
https://gcc.gnu.org/onlinedocs/gfortran/ACOSH.html.
