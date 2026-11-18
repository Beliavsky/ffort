# Bounded model decomposition and ASCII code

FRACTION(X), EXPONENT(X) and SET_EXPONENT(X,I) accept finite REAL(4) or REAL(8)
X. SET_EXPONENT's I is INTEGER(4) or INTEGER(8). FRACTION and SET_EXPONENT return
X's REAL kind; EXPONENT returns default INTEGER(4). All three support elemental
rank 0–3 arrays and scalar expansion with conformable shapes. Standard keywords,
including reversed I/X order, and supported constant expressions are retained.

IACHAR(C[,KIND]) accepts default CHARACTER with element length one, including
rank 0–3 arrays. The result is INTEGER(4), or INTEGER(4/8) selected by a supported
scalar constant KIND expression. It returns ASCII codes 0:127. Known invalid
lengths are rejected at source checking; assumed lengths are checked when values
are evaluated. Other character kinds and non-ASCII codes remain unsupported.
All four names remain nonreserved. Explicit scalar, array, function-result,
procedure and generic-interface shadows are tested.

## Zero, ranges and inquiry behavior

FRACTION and SET_EXPONENT preserve the tested IEEE sign of zero. EXPONENT of
zero is 0. Normal and subnormal input decomposition is performed at the input's
REAL kind. SET_EXPONENT checks a possibly INTEGER(8) exponent before any host
integer narrowing. Zero stays zero for any representable I. For nonzero X,
I>128 for REAL(4), or I>1024 for REAL(8), is an overflow diagnostic. Bounded
near-underflow exponents are evaluated with the host's gradual-underflow
rounding; lower exponents produce signed zero. Finite-value enforcement remains
unchanged; no general infinity or NaN support is added.

The runtime independently validates public-IR type/kind, arity, slots, shape,
CHARACTER descriptor length and constant KIND metadata. It includes literal and
declaration consistency checks. KIND inquiries and empty arrays cannot bypass
structurally malformed expressions, but they do not evaluate unused data values.

## Complete original examples

Three full files from `urbanjost/M_intrinsics` commit
`fc14233036d910e3678d350efc24609e11475067` pass unchanged:

- demo_fraction.f90
- demo_set_exponent.f90
- demo_iachar.f90, including its complete lowercase helper

`tests/model_decomposition/upstream.json` records their byte hashes and original
paths, and the upstream MIT license is preserved. The complete unchanged
`demo_exponent.f90` is retained as an explicit rejection boundary: it also needs
binary formatting, MINEXPONENT/MAXEXPONENT, and IEEE nonfinite facilities.
It is not counted as a passing original and is not edited or partially run.

## Verification and oracle limitations

The 45 focused fixtures include the original files, 84 independently calculated
binary-model values, all 128 ASCII inverse codes, kind/rank/keyword checks,
source rejections, runtime errors and declaration shadows. GNU executes 22,
compiles 10 without execution, and rejects 13. Unsafe/undefined inputs and the
full nonfinite exponent demonstration are never executed by the ordinary GNU
runner. 3032 native assertions cover adapter, value, KIND and empty-array
corruption paths; 21 independent producer cases verify metadata and bindings.
Seven harness self-tests reject invalid exits, diagnostics, output leaks,
nonfinite results, integer rounding and loss of subnormals.

GNU14.2 has observed SET_EXPONENT discrepancies in extreme INTEGER(8) runtime
exponents and maximum-value constant folding. Constant underflow expressions
also trigger compile-time diagnostics that their variable equivalents avoid.
The complete evidence is isolated under `tests/model_decomposition/oracle-limitations/`.
Ordinary variable normal/subnormal fixtures still use strict differential
comparison. No generic comparator is weakened, and discrepancy outputs are not
accepted as alternative candidate answers.

Primary references: [GNU FRACTION](https://gcc.gnu.org/onlinedocs/gfortran/FRACTION.html),
[GNU EXPONENT](https://gcc.gnu.org/onlinedocs/gfortran/EXPONENT.html),
[GNU SET_EXPONENT](https://gcc.gnu.org/onlinedocs/gcc-12.3.0/gfortran/SET_005fEXPONENT.html),
and [GNU IACHAR](https://gcc.gnu.org/onlinedocs/gfortran/IACHAR.html).
