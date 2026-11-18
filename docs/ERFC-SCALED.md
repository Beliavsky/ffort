# Bounded ERFC_SCALED

`ERFC_SCALED(X)` is a Fortran 2008 elemental intrinsic returning the same REAL
kind and shape as X. This implementation supports REAL(4/8), scalar or rank one
through three, with one positional or `X=` argument. It composes with supported
sections, constructors, array functions, row gathering, constant expressions and
masked WHERE/FORALL evaluation. Declared objects/functions/generics retain
precedence over the intrinsic. See the
[GNU specification](https://gcc.gnu.org/onlinedocs/gcc-15.1.0/gfortran/ERFC_005fSCALED.html).

## Stable finite-domain evaluation

The mathematical function is exp(x²) erfc(x), but the interpreter does not use
that naive product. It can overflow or underflow intermediate values even when
the desired result is representable.

- The central region uses the host scaled intrinsic, with REAL4 inputs widened
  and the result rounded to REAL4 only once at the end.
- For negative X below −1, reflection is evaluated as
  2 exp(z²) exp(delta) − erfc_scaled(abs(x)), where z is abs(x) truncated on a 1/16
  grid and delta=(abs(x)−z)(abs(x)+z). In the explicitly bounded domain, z² is
  exact and the split retains the residual without squaring the full input.
- For X≥1e8, the result is `(1/sqrt(pi))/x`. The omitted relative asymptotic
  correction is bounded by 5e-17. Dividing the constant by X avoids overflowing
  `sqrt(pi)*x` and preserves positive subnormal answers through HUGE(REAL64).
  The expansion and positive-real remainder bound follow
  [DLMF7.12.1](https://dlmf.nist.gov/7.12).

NaN/Infinity inputs remain rejected. Negative values whose mathematical result
exceeds the supported kind are rejected **before** host evaluation. The last
accepted representable negative inputs are:

- REAL4: −9.3824138641357421875, binary magnitude0x1.2c3cbcp+3.
- REAL8: −26.628735713751489, binary magnitude0x1.aa0f4d2e063cep+4.

The next more-negative neighbor overflows for each kind. Independent 120-digit
boundary records and native neighbor tests verify these limits. Every finite
positive input is supported, including inputs whose result is subnormal.
The overall array/storage cap is unchanged.

## Independent validation and known GNU differences

The accuracy corpus contains 439 exact-binary inputs: 215 REAL4 and 224 REAL8, covering
central values, transition neighbors, extreme negative finite values, subnormals,
large positive tails and deterministic random samples. References are generated
at 120 decimal digits with mpmath 1.3.0. For positive X>50, an independent 120-term
asymptotic reference has a first-omitted-term relative bound below 1e-120.
Reference generation never depends on the interpreter or GNU result.

The acceptance budgets are 2 ULP for REAL4 and 4 ULP for REAL8; zero cannot pass for
an expected positive subnormal. On the verified GNU 14.2 build the observed
candidate maxima were 0.500 ULP and 2.143 ULP respectively. These are measured results,
not an exhaustive accuracy proof for every representable input or host compiler.

GNU 14 runtime prematurely returns positive Infinity for some finite negative
endpoint results and zero for some positive subnormal results. Eleven such
mathematical-reference discrepancies are recorded separately: 5 REAL4 and 6 REAL8.
The candidate must satisfy the mathematical reference on all of them. GNU
constant folding can differ from its runtime library. These cases are not
reported as GNU/candidate execution agreement, and no arbitrary absolute
error tolerance hides them. Other unexpected GNU discrepancies fail the runner.

Native tests separately exercise producer kind/rank, source-bound call forgery,
adapter/runtime metadata corruption, KIND/empty paths, forged nonfinite values,
last finite negative inputs, overflow neighbors and positive extreme inputs.
KIND remains unevaluated while validating metadata. Masked-out invalid values
are not read. No new IEEE exceptional-value construction or implicit typing is
introduced.

## Original example and reproduction

`tests/erfc_scaled/demo_erfc_scaled.f90` is the complete unchanged M_intrinsics
example at commit fc14233036d910e3678d350efc24609e11475067, including its initialized
REAL64 X=0.17. No wrapper, helper or source change is needed. Its MIT license and
source hash are retained and verified in `provenance.json`.

    python3 tests/erfc_scaled/test_runner.py
    python3 tests/erfc_scaled/test_accuracy.py
    python3 tests/erfc_scaled/run_tests.py --candidate /absolute/path/to/fortfront-interpreter
    python3 tests/erfc_scaled/run_accuracy.py --candidate /absolute/path/to/fortfront-interpreter

The ordinary verifier only needs Python's standard library; checked-in accuracy
references require no mpmath installation. To regenerate references deliberately,
run `generate_accuracy.py` with mpmath 1.3.0. GNU oracles use Fortran2018 mode,
bounds/runtime checks and invalid/zero/overflow traps. Native interpreter tests
use the repository's official debug profile, not a claimed `-fcheck=all` build.
