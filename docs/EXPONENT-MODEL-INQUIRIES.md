# MINEXPONENT and MAXEXPONENT

`MINEXPONENT(X)` and `MAXEXPONENT(X)` accept REAL kind 4 or 8 and return a
scalar default INTEGER (kind 4), regardless of X's rank. The X keyword is
supported. There is no result KIND option. On the verified GNU binary32/binary64
host, the minimum/maximum pairs are `-125, 128` and `-1021, 1024`. These are
Fortran model exponents, not an added REAL128 arithmetic capability.

## Metadata-only subset

Whole scalars and rank-one/rank-two/rank-three arrays are supported, including
empty and undefined arrays. Existing declaration limits still apply. Whole
unallocated allocatables, undefined/disassociated rank-one pointers and absent
OPTIONAL arguments are safe: the inquiry uses the declared REAL kind and does
not read values, shape, presence or pointer association state. KIND of either
result is 4 and does not evaluate X.

Typed arithmetic, constructors and supported function expressions are accepted
in ordinary inquiries. The interpreter intentionally does not execute those
expressions or their side effects. GNU differential tests record the same
behavior for the tested programs; this is not a promise that every Fortran
processor must omit every side effect.

Subobject operands are deliberately unsupported for these two new inquiries,
including array elements, sections, derived components, substrings and row
selection, even when nested inside another expression. Valid present sections
are therefore a documented subset boundary. This also avoids accepting absent
OPTIONAL subobjects or depending on invalid unallocated/disassociated element
selection. Earlier EPSILON/RADIX/TINY/HUGE behavior is not expanded by this work.

For PARAMETER initializers and constant declaration bounds, these new inquiries
accept whole eligible variables or constant operands. A nonconstant arithmetic
expression, parenthesized nonconstant variable or user-function call is not
accepted merely because the compiler could fold the outer inquiry. GNU 14.2
accepts several such cases; they are compile-only boundaries, not runtime oracle
agreements or rewritten source fixtures.

The parser, independent frontend and runtime validate argument count, keyword
association, REAL kind, scalar INTEGER result and nested expression metadata.
Empty surrounding expressions and nested KIND retain those checks. A bounded,
memoized structural scan rejects subobjects and cycles without executing X.

## Original programs and verification

`tests/exponent_inquiries/demo_minexponent.f90` is the complete unchanged
M_intrinsics program. Its unused REAL128 import is accepted by the previously
implemented ISO_FORTRAN_ENV subset. It executes both output rows and agrees
with GNU. Original bytes, commit and upstream license are SHA-256 pinned in
`tests/exponent_inquiries/upstream.json`.

The unchanged `demo_maxexponent.f90` remains unsupported. Named CHARACTER
PARAMETER formats now advance it to line 7, column 33:
`Only REAL literal kinds 4 and 8 are supported`. Its REAL128 literal remains
outside the supported arithmetic kinds. Only the expected diagnostic is migrated;
its rejection category, GNU-compile-only mode and original source bytes are
unchanged. No altered original is represented as complete execution.

The focused runner covers GNU executions, GNU compile rejections and compile-only
subset boundaries separately. Independent native tests cover both inquiry names,
both real kinds, ranks 0–3, empty contexts, malformed IR, nested KIND and a shared
48-level DAG/cycle. Producer tests check default INTEGER rank/kind and declared
array-name shadowing. Vendor patch 0069 supplies only registration and metadata.

## Primary references

[F2018 interpretation document J3/18-007r1](https://j3-fortran.org/doc/year/18/18-007r1.pdf):
16.9.126 (MAXEXPONENT), 16.9.132 (MINEXPONENT), 16.1 paragraph 2 (whole inquiry
argument state), 10.1.12 (constant expressions), and 15.5.2.12 paragraph 3(4–5)
(absent OPTIONAL restrictions and the constant-expression exception).
GNU references: [MINEXPONENT](https://gcc.gnu.org/onlinedocs/gfortran/MINEXPONENT.html)
and [MAXEXPONENT](https://gcc.gnu.org/onlinedocs/gfortran/MAXEXPONENT.html).
