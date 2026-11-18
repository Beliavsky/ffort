# DIGITS, NEW_LINE and RRSPACING

This bounded extension keeps the three names nonreserved. A declared scalar,
array, function result, procedure or named generic of the same name retains its
normal binding. The parser, producer metadata, source-bound adapter and direct
runtime IR checks each preserve the intrinsic signature and result metadata.

- `DIGITS(X)` accepts INTEGER4/8 or REAL4/8 scalar and rank-one/two/three operands.
  It returns scalar default INTEGER: 31, 63, 24 or 53 respectively. Like the
  existing numeric-model inquiries, it examines type and kind without evaluating
  data, function bodies or section bounds. Undefined whole objects, unallocated
  arrays and absent OPTIONAL whole dummies are covered. The existing component
  operand restriction remains; this is not general support for derived data.
- `NEW_LINE(A)` accepts default CHARACTER scalar and rank-one/two/three operands
  and returns scalar default CHARACTER of length one. On the verified ASCII
  processor the returned code is 10. `A` is the standard keyword; `C` is rejected,
  despite the GNU documentation's synopsis using that letter. A whole object,
  literal or supported typed expression is inspected without evaluating its
  value or executing user functions. Empty arrays, undefined values, absent
  OPTIONAL dummies, and unallocated deferred-length scalars/arrays are covered. All
  subobject operands (elements, sections, substrings, components and row gathers)
  remain explicitly outside this bounded NEW_LINE subset. Scalar ALLOCATABLE
  declarations use the companion scalar CHARACTER contract. Wider CHARACTER
  kinds are unsupported. Internal CHARACTER metadata uses kind 4, while language `KIND`
  returns the supported default CHARACTER kind 1.
- `RRSPACING(X)` accepts finite REAL4/8 scalar and conformable elemental array
  expressions through rank three, returning the same REAL kind and shape.
  It computes `SCALE(ABS(FRACTION(X)),DIGITS(X))` in the actual kind. This avoids
  dividing by a spacing that may underflow. Both signed input zeros return
  positive zero; subnormal, minimum-normal and largest-finite inputs are covered.
  Nonfinite evaluated values and forged REAL4 values outside its finite range
  are rejected. KIND remains a structural inquiry, not a data evaluation.

Arity, keyword association, unsupported kinds/ranks, cycles, literal caches,
declaration identity, result shape and metadata are checked even under KIND
or an enclosing empty expression. Shared expression DAGs are memoized. Newly
added loop variables are local; whole-array, strided, WHERE, FORALL and enclosing
DO assignments test that expression evaluation cannot change assignment counters.
No existing value, expression-depth, output or execution budget is increased.

## Complete upstream examples and profiles

`tests/model_character_intrinsics/cases/demo_digits.f90` and `demo_rrspacing.f90`
are complete unchanged files from urbanjost/M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`. Their original hashes and MIT license
are retained in the suite. Neither example is rewritten, wrapped or replaced by
a synthetic approximation.

The intrinsic-only profile executes demo_rrspacing byte-for-byte like GNU, and
requires demo_digits to stop at its unsupported colon format. The separate
[colon format correction](COLON-FORMATS.md) enables its `(*(g0:,1x))` statement.
With `--with-colon-formats`, both complete original programs must execute with
byte-exact GNU output. The total stays 120 cases; only the explicit demo_digits
expectation changes. A profile never accepts either success or rejection.

## Validation

The frozen intrinsic-only executable passed all 120 focused source cases,
5,007 targeted adapter/runtime/numerical assertions, 14 independent producer
cases and 28 adversarial harness tests. Strict GNU Fortran 14.2 compiled all
fixtures: 91 were executed, 10 were compile-only bounded-language cases and 19
were expected compiler rejections. All ordinary numeric comparisons are exact
Decimal comparisons, including signed zero; original formatted output is exact.
The colon-enabled build also passes all 120 cases with the combined profile.
This is focused verification, not a claim that this worker ran the full native
release suite. The release integrator performs the final clean aggregate.

The RRSPACING native bit-pattern oracle derives the normalized significand
integer directly from IEEE binary32/binary64 bits, without calling RRSPACING,
FRACTION or SCALE for its expected answer. It covers 340 finite signed bit
patterns and 1,364 assertions. Other checks independently exercise malformed
public IR, nonfinite evaluated inputs and no-evaluation inquiry paths.

References: [GNU DIGITS](https://gcc.gnu.org/onlinedocs/gfortran/DIGITS.html),
[GNU RRSPACING](https://gcc.gnu.org/onlinedocs/gcc-10.4.0/gfortran/RRSPACING.html),
[J3 NEW_LINE proposal](https://j3-fortran.org/doc/year/03/03-167r1.pdf), and
[NAG inquiry semantics](https://support.nag.com/nagware/np/r72_doc/manual/compiler_9_7.html).
