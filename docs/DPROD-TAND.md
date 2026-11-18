# Double product and finite degree tangent

DPROD(X,Y) accepts two default REAL(4) operands and returns REAL(8). It widens
both represented operands before multiplying, rather than multiplying in REAL4
and widening the rounded result. Every product of two finite REAL4 operands fits
in REAL8, including products of tiny/subnormal values. INTEGER, REAL8, REAL16 and
complex operands are rejected. X/Y keywords, reversed order, scalar expansion,
conformable rank-one/rank-two/rank-three arrays, dynamic dummy arrays and empty
arrays are supported. Evaluated nonfinite values are rejected.

TAND(X) returns degree tangent in X's REAL(4/8) kind, elementally at ranks 0–3.
This bounded implementation accepts finite |X| <= 1048576 degrees, excluding
odd multiples of 90 degrees. Larger finite arguments and poles produce checked
runtime diagnostics; no infinity or NaN result is provided. Reduction occurs in
degrees before radians conversion. Complementary angles near a pole avoid loss
from subtracting an angle from pi/2. Exact multiples of 45 degrees use exact
identities. Tiny values use gradual underflow, and zero signs follow the tested
IEEE host contract. No general REAL16 or complex support is added.

TAND is a Fortran 2023 intrinsic. GNU 14.2 reference tests use `-std=gnu` to expose
its implementation; no Fortran 2018 conformance is claimed for TAND. DPROD and the
DOUBLE PRECISION spelling use strict Fortran 2018 reference flags. The interpreter
implementation itself uses standard real arithmetic and TAN, not a compiler's
TAND extension.

Both names remain nonreserved. Scalar, array, function-result, user-procedure
and generic shadows are tested. Parser, producer adapter and runtime independently
validate argument count, keyword slots, type, kind and shape. Runtime full-tree
validation checks cache/declaration consistency and direct/indirect cycles.
DPROD's fixed REAL8 result cannot hide inconsistent REAL4 operand metadata.
KIND and empty-array paths validate structure without evaluating unused data,
including undefined and absent OPTIONAL arguments.

## Complete original programs

The complete unchanged M_intrinsics `demo_dprod.f90` and `demo_tand.f90`, from
commit fc14233036d910e3678d350efc24609e11475067, pass checking and execution.
The DPROD program retains compact DOUBLEPRECISION declarations and all displayed
comparisons and elemental calls. TAND retains its ISO_FORTRAN_ENV imports,
including the unused REAL128 name; the existing unsupported-kind sentinel does
not add REAL128 arithmetic. Byte hashes and the upstream MIT license are stored
under tests/dprod_tand/. DOUBLE PRECISION spelling coverage is documented in
DOUBLE-PRECISION.md, including contextual identifier safeguards.

## Verification

The DPROD/TAND suite has 67 source cases: 39 GNU executions, eight compile-only
cases and 20 GNU rejections. It includes both complete originals, 144 independent
exact products, and 55 independently computed degree-tangent reference values.
The high-precision reference computes pi using Machin's arctangent series and
sine/cosine using Decimal arithmetic after exact represented-degree reduction.
The comparator uses Decimal tokens, preserving exact distinctions and signed
zero. Exact product cases use zero tolerance. REAL4 transcendental display
comparisons use relative tolerance 2e-6; the independent REAL8 grid uses 1e-13,
with tighter bounds on the original demo and selected cases. Absolute tolerance
is zero for small-value accuracy cases. No comparator accepts nonfinite output.

Two native programs contain 1,244 independent runtime/adapter assertions and
14 producer cases. The spelling suite adds 26 source cases and 83 native checks.
Each source runner has 15 fail-closed harness self-tests. The source fixtures
cover keyword order, declared shadows, scalar/array results, KIND, empty arrays,
source rejection and evaluated-domain failures. Native tests also inject invalid
metadata, cache kinds, expression cycles and nonfinite values.

## GNU reference limitations

Two isolated inputs are GNU compile-only rather than falsely labeled execution
agreements. For the nearest binary64 inputs on either side of 90 degrees, GNU
14.2 runtime and constant calls yield approximately +/-3.5301143212171575e15.
The independent 110-digit reference and explicit complementary-angle formula
round to +/-4.0318320510159320e15, agreeing with this implementation. Separately,
GNU's runtime REAL4 TAND of negative zero loses its sign, while its literal
constant call preserves it. The bounded interpreter preserves the sign in both
forms. This is a tested local IEEE contract, not a claim that every Fortran
processor must preserve zero signs.

Exact source, compiler version, -O0/-O2 commands and outputs are retained in
`tests/dprod_tand/oracle-limitations/`. No compiler-source cause is asserted.
These results are not alternate accepted answers and ordinary comparisons retain
their explicit tolerances. Original programs are never altered to bypass a gap.

Primary descriptions: https://gcc.gnu.org/onlinedocs/gfortran/DPROD.html and
https://gcc.gnu.org/onlinedocs/gfortran/TAND.html.
