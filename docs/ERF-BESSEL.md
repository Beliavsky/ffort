# Bounded ERF and Bessel intrinsics

This increment implements Fortran 2008 elemental `ERF`, `BESSEL_J0`, `BESSEL_J1`,
`BESSEL_JN`, `BESSEL_Y0`, `BESSEL_Y1` and `BESSEL_YN`. REAL kinds 4 and 8,
scalars and ranks 1–3, scalar broadcasting and conforming arrays are supported.
Results preserve X's REAL kind and the merged elemental shape. Unary forms accept
X or X=; JN/YN accept N,X or keywords in either order. N may be INTEGER kind 4 or 8,
scalar or conforming array. The three-argument transformational JN/YN forms are
not implemented. User objects, procedures and generics retain their binding
precedence; these spellings are not newly reserved identifiers.

## Deliberate finite bounds

- ERF accepts every finite representable REAL4/8 argument.
- All Bessel functions require `abs(X) <= 2**20` (1,048,576).
- JN/YN require `0 <= N <= 32`. Negative orders remain outside this bounded contract.
- Y0/Y1/YN additionally require `X >= 2**(-20)` (0.00000095367431640625).
- NaN and Infinity remain unsupported, including forged runtime values.
- A finite REAL64 evaluation whose result exceeds HUGE(REAL4) is rejected before
  narrowing to REAL4. Rounding to a finite subnormal or zero is allowed.

These are implementation limits, not the complete mathematical domains. In
particular, Y0(0) is singular and is rejected before a host intrinsic call.
The untouched original `demo_bessel_y0` deliberately remains a runtime rejection.
No example is rewritten to substitute X=1, skip the call or print a synthetic value.
All existing storage and execution limits are unchanged.

## Evaluation and numerical evidence

Each elemental input is validated before evaluation. N is range-checked in
INTEGER64 before conversion to a host default integer. REAL4 X is widened exactly
to REAL64; the host's REAL64 ERF/Bessel intrinsic is evaluated, and a supported
REAL4 result is rounded once at the end. The bounded order and positive Y argument
avoid singular evaluations and extreme-order recurrences. Scalar metadata is
validated before access; array metadata, source bindings, type/kind/count, rank,
shape and intrinsic slots are independently checked by the parser, adapter and
runtime. KIND and empty-expression paths validate metadata without evaluating X
or N values. Masked WHERE/FORALL calls do not evaluate excluded elements.

The checked-in reference corpus contains 1,818 exact binary input points with
120-decimal-digit mpmath 1.3.0 references, independent of GNU/libm output. It covers
all seven functions and both kinds, orders 0,1,2,5,16,32, exact domain endpoints,
signed zero, tiny and subnormal J/ERF inputs, deterministic linear/log samples,
and the nearest representable neighbors of the first, second, third and twentieth
positive zeros for each Bessel order. REAL4 cases whose true result overflows are
covered by explicit runtime rejection tests rather than accepted reference rows.

Fixed numerical budgets:

- ERF: 2 ULP for REAL4 and 4 ULP for REAL8.
- Nonoscillatory Bessel region: 4 epsilon relative for REAL4 or 64 epsilon relative
  for REAL8, plus twice the smallest subnormal.
- Oscillatory region `abs(X) >= max(1,N)`, and explicit root-neighbor probes:
  16 epsilon times `max(abs(reference),sqrt(2/(pi*abs(X))))`, plus twice the smallest
  subnormal. This is an amplitude-scaled absolute budget, not a relative claim at
  zeros. Non-root normal results may not collapse to zero.

An initial relative-only oscillatory test was inappropriate near a higher Bessel
zero: Y32(82.46216509639774) has a result near 0.00005895 and an oscillation amplitude
near 0.08786. Both host and candidate had about 1.43e-17 absolute error, but this is
about 2.43e-13 relative to the tiny result. The final budget explicitly handles
this conditioning for the entire oscillatory region, and the corpus was expanded
to four sets of zero neighbors. The original failing result/reference reports
are retained in development evidence; no mathematical reference was changed to match
candidate output.

All 1,818 candidate points pass. The largest observed budget fractions are below
0.25 for REAL4 and below 0.36 for REAL8. These are measured corpus results, not an
exhaustive accuracy theorem for every input or host math library.

GNU 14.2 comparisons are separate. The stricter independent test records one
known GNU REAL4 precision difference: J16(8) yields
0.000078006436524447054 versus the 120-digit reference beginning
0.000078006395467308272965416011827. That is about 1.104 times our four-epsilon
relative budget. The widened candidate passes. The runner recognizes only this
exact recorded result, argument/order/kind and bounded error; other GNU errors
are failures. This one point is not claimed as mathematical-budget agreement.
The 63 ordinary source contracts include separate GNU/candidate executions.

## Original source provenance and tests

Seven complete M_intrinsics example files are copied byte-for-byte from commit
`fc14233036d910e3678d350efc24609e11475067`, with upstream MIT license and individual
SHA-256 records in `tests/erf_bessel/provenance.json`. The six finite original
programs execute unchanged; Y0(0) remains the explicit singularity boundary.
No wrapper, dependency replacement or helper is used.

Focused tests also cover keyword order, INTEGER8 N, array N, broadcasts, rank2/3,
sections and row gathering, source-name shadowing, constants, empty values,
unevaluated KIND, masked safety, domain/overflow boundaries and static rejections.
Native tests add 294 parser/adapter/runtime checks and 44 independent producer
queries, including malformed public IR and source-bound calls forged as intrinsic.
Runner self-tests preserve text case, exact integers, numeric-only D/E handling,
clean silent --check, nonfinite rejection, count/order and mathematical budgets.

Reproduce from the repository root:

```
python3 tests/erf_bessel/test_runner.py
python3 tests/erf_bessel/test_accuracy.py
python3 tests/erf_bessel/run_tests.py --candidate /absolute/path/to/fortfront-interpreter
python3 tests/erf_bessel/run_accuracy.py --candidate /absolute/path/to/fortfront-interpreter
```

Optional regeneration uses `python3 tests/erf_bessel/generate_accuracy.py` with
mpmath 1.3.0. Ordinary verification needs only the standard Python library,
gfortran and candidate. GNU oracles use `-std=f2018 -pedantic-errors -fcheck=all
-ffpe-trap=invalid,zero,overflow`; the interpreter's official profile remains fpm
debug (bounds/array-temp checks), not a claimed interpreter `-fcheck=all` run.

## Primary references

- [GNU ERF](https://gcc.gnu.org/onlinedocs/gfortran/ERF.html)
- [GNU BESSEL_JN](https://gcc.gnu.org/onlinedocs/gfortran/BESSEL_005fJN.html)
- [GNU BESSEL_YN](https://gcc.gnu.org/onlinedocs/gfortran/BESSEL_005fYN.html)
- [DLMF Bessel definitions](https://dlmf.nist.gov/10.2),
  [power series](https://dlmf.nist.gov/10.8) and
  [large-argument oscillatory expansions](https://dlmf.nist.gov/10.17)
- [DLMF error-function definitions](https://dlmf.nist.gov/7.2)
