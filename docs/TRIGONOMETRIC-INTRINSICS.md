# Real trigonometric intrinsics

`SIN(X)`, `COS(X)` and `TAN(X)` accept one REAL argument of kind 4 or 8,
positionally or with the `X` keyword. Angles are in radians. The result preserves
type, kind and scalar/rank-one/rank-two shape. Sections, expression inputs,
PARAMETER initializers, supported pure/elemental procedures and empty arrays are
supported. REAL(4) uses the single-precision host intrinsic; REAL(8) uses the
double-precision intrinsic. Inputs are not reduced or approximated by application
code. Evaluated non-finite results remain checked runtime errors.

KIND inquiries validate descriptors without evaluating their data. Invalid
argument count/type/kind/shape metadata is rejected independently by the adapter
and runtime, including calls whose result has zero elements and calls nested inside empty
array arithmetic or reductions. A metadata-only traversal preserves unevaluated
data while preventing an enclosing expression from bypassing these checks. The existing shared
work and storage limits apply.

This does not add COMPLEX, REAL kinds other than 4/8, inverse trigonometric
functions, or legacy specific aliases such as DSIN/DCOS/DTAN. Unknown/duplicate
keywords, extra/missing arguments and positional arguments after keywords fail
before output. SIN, COS and TAN join the documented interpreter-reserved names;
Fortran itself does not reserve them.

## Original utility coverage

The five complete procedure bodies `sine_bound`, `half_sine_bound`,
`sine_transform`, `half_sine_transform` and `piecewise_sine` are retained from
`xutilities.f90`, with CRLF-to-LF normalization only. The original shared numeric
constant declaration is also retained. A reduced wrapper supplies DP and a new
main program exercises scalar, rank-one/rank-two, reverse sections, empty inputs,
saturation endpoints and zero-width intervals. Body lines and hashes are in
`tests/trigonometric_intrinsics/utility-provenance.json`, and the runner verifies
them against the retained full original source before executing tests.

These are five original-body successes, not execution of the complete utility
module or original main. The unmodified full source still encounters other
unsupported features.

## Verification

- `fpm test --profile debug --target test_trigonometric_intrinsics` runs 610
  adapter, runtime, kind-preservation, unevaluated KIND and empty-result assertions.
- `python3 tests/trigonometric_intrinsics/run_tests.py --candidate PATH` runs GNU
  differential successes, language-invalid arguments, legal unsupported boundaries
  and undefined-value runtime safety cases. Large finite and very small inputs
  are included. The utility fixture also asserts independently known endpoint and
  zero-width results.
- `scripts/verify.py` runs both new checks alongside every existing suite.
