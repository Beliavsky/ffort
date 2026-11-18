# Local patch 0006: exponent-only real literals and ERFC

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. This local interpreter-project fix
retains the upstream MIT copyright/license in `vendor/fortfront/LICENSE` and
makes no claim of upstream endorsement.

- The expression parser previously classified a numeric literal as REAL only
  when it contained a decimal point. It now also recognizes E/D exponents,
  including `1e-08_dp` and `1D-08`. The kind suffix is excluded from this test,
  so an integer such as `1_width` does not become REAL because its suffix
  contains an exponent-marker letter.
- ERFC is registered as a REAL-to-REAL intrinsic. This preserves the input REAL
  kind through existing intrinsic inference and resolved-type annotation, and
  prevents a valid main-program ERFC call from being diagnosed as an external
  function without an explicit interface. The registry count is updated.

The automatically discovered native test
`test/test_named_real_kind_frontend.f90` covers decimal-point-free E/D literals,
uppercase exponents, real32/real64 mismatches, integer suffixes containing d,
and ERFC intrinsic classification and real64 result metadata. The independent
numerical cases `bs_tiny_vol.f90` and `real64_intrinsics.f90` also exercise these
paths. No semantic-error bypass is introduced.
