# REAL conversion with optional KIND

`REAL(A [, KIND])` accepts INTEGER(4/8) or REAL(4/8) scalars and supported
rank-one through rank-three expressions. A scalar INTEGER constant KIND selects
REAL(4) or REAL(8). Positional, named and reordered `A`/`KIND` association is
supported. Without KIND, the result is default REAL(4), including when A is
REAL(8). The result retains A's rank and extents; empty arrays remain empty.
See the [GNU REAL reference](https://gcc.gnu.org/onlinedocs/gfortran/REAL.html).

The parser, strict producer adapter and source-independent runtime independently
validate argument count, operand type/kind, constant KIND and result metadata.
KIND inquiries inspect the conversion's metadata without evaluating A, including
undefined or unallocated operands. Constant KIND expressions may themselves use
supported metadata inquiries. A variable KIND, unsupported kind, malformed
argument association, metadata cycle or inconsistent result cache is rejected.

Conversion rounds to the selected kind. INTEGER(8) to REAL(4) converts directly
to binary32, avoiding a binary64 intermediate that could double-round integers
near a binary32 midpoint. REAL(8) narrowing uses the normal binary32 conversion.
The existing finite-value policy rejects overflow/nonfinite conversion results.
COMPLEX and other integer/real kinds remain outside this interpreter subset.
Ordinary array assignment retains existing RHS snapshot and alias behavior.

Producer metadata now follows the same default-kind rule and resolves KIND by
keyword rather than physical argument position. This does not change declaration
kind selectors or introduce additional intrinsic spellings.

## Verification

`test/test_real_conversion.f90` exercises independent adapter, runtime and KIND
metadata mutations, scalar/empty-array paths, direct and indirect cycles,
nonfinite runtime values and exact kind-rounding boundaries. The focused source
suite is `tests/real_conversion/run_tests.py`; GNU is an independent oracle, not
an execution backend. Unsafe/undefined and interpreter-policy inputs are compiled
but never executed by GNU. Historical Fortran fixtures remain unchanged.
