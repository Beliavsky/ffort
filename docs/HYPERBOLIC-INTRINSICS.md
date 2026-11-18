# Real hyperbolic intrinsics

`SINH(X)`, `COSH(X)` and `TANH(X)` accept one REAL argument of kind 4 or 8.
The argument may be positional or supplied with keyword `X`. The result has
exactly the input type, kind and shape. Scalar, rank-one and rank-two inputs,
sections, array expressions and zero-sized arrays use the existing elemental
shape and bounded-evaluation paths. Calls are permitted in PARAMETER
initializers and in pure/elemental routines.

REAL(4) computations use native single-precision intrinsics, rather than computing
in double precision and rounding the answer. REAL(8) uses double precision.
As with the existing numerical intrinsics, an evaluated non-finite result is a
runtime error. In particular, large-magnitude SINH/COSH inputs may overflow;
TANH approaches +/-1 without the overflow of a naive exponential formula.
KIND queries validate expression metadata without evaluating the argument, so
`kind(cosh(1000.0d0))` returns 8 and inquiries about undefined real variables are
allowed. Invalid metadata is also rejected when an array has no elements.

This does not add COMPLEX, REAL(10/16), inverse hyperbolic functions
or legacy specific-name aliases. Unsupported argument types, empty
calls, additional actuals, unknown or duplicate keywords, and positional actuals
after keywords are rejected before execution.

Real SIN/COS/TAN are covered separately in [TRIGONOMETRIC-INTRINSICS.md](TRIGONOMETRIC-INTRINSICS.md).

The unchanged `sech` procedure from `xutilities.f90` lines 542-547 now executes
in `tests/utilities_slices/blocked_hyperbolic.f90`; the historical fixture name is
retained. This is one additional original utility routine, not a claim that the
complete utility module can execute. The original source and body hash stay
unchanged.

## Verification

- `fpm test --profile debug --target test_hyperbolic_intrinsics` checks original
  adapter metadata against independent mutations, runtime values and malformed IR,
  unevaluated KIND, and zero-sized result validation.
- `python3 tests/hyperbolic_intrinsics/run_tests.py --candidate PATH` compares
  successful scalar, rank-one/rank-two, section, constant and procedure calls to
  GNU Fortran, rejects malformed source, and checks overflow diagnostics.
- The existing utilities runner now compares the original `sech` slice to GNU.
- `scripts/verify.py` includes the hyperbolic suite.

Semantics: GNU Fortran's [SINH](https://gcc.gnu.org/onlinedocs/gfortran/SINH.html),
[COSH](https://gcc.gnu.org/onlinedocs/gfortran/COSH.html) and
[TANH](https://gcc.gnu.org/onlinedocs/gfortran/TANH.html) documentation.
