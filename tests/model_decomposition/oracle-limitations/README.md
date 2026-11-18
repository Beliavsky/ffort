# GNU14 SET_EXPONENT observations, separate from ordinary comparisons

`gnu14-receipt.json` records exact source hashes, commands and output using
GNU Fortran 14.2.0 with `-std=f2018 -pedantic-errors -fcheck=all,no-array-temps`
at both `-O0` and `-O2`. These observations are not successful differential tests.

- With runtime INTEGER(8) I=-HUGE, GNU returns [1,-1] for X=[1,-1], whereas
  its literal constant evaluation returns signed zeros. I=INT64_MIN gives
  runtime [.5,-.5]. The inputs satisfy the intrinsic's type/kind requirements.
  The bounded IEEE implementation's enormous negative exponent policy is
  underflow to signed zero, with checks before narrowing I. No compiler-source
  cause is asserted; narrowing is a hypothesis only.
- SET_EXPONENT(HUGE(REAL),maximum exponent) as a constant folds to half of HUGE
  for REAL(4) and REAL(8). Equivalent runtime variables and the candidate return
  HUGE, which is representable and independently expected from the model.
- Some constant expressions at the lowest subnormal boundary are rejected by
  GNU's constant evaluator for underflow. Equivalent runtime-variable fixtures
  compile and pass strict numeric comparison, with absolute tolerance 0 so a
  lost subnormal is not accepted as zero.

The main suite keeps extreme INTEGER(8) exponent tests GNU compile-only with an
independent candidate expectation. Normal/subnormal variable cases remain strict
GNU differential executions. Frozen constant-source evidence is preserved here,
without changing the candidate to reproduce observed oracle discrepancies.

The [GNU SET_EXPONENT specification](https://gcc.gnu.org/onlinedocs/gcc-12.3.0/gfortran/SET_005fEXPONENT.html)
permits a REAL X and INTEGER I and retains X's REAL kind. This evidence concerns
finite supported binary kinds and their bounded underflow/overflow policy; it
adds no support for arbitrary nonfinite values.
