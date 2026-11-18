# 0066: CSHIFT producer registration and ARRAY metadata

Local MIT-licensed FortFront changes originally validated on frozen 0.37 through
patch 0062, rebased here after patches 0063 through 0065. Apply from
`vendor/fortfront` with `patch -p1 --fuzz=0`. The cumulative registry count moves
from 90 to 91, retaining the independently registered ERFC_SCALED entry and all
ISO import and ASSOCIATED metadata corrections.

- Register standard transformational CSHIFT so strict explicit-interface checks
  recognize it as an intrinsic.
- Copy semantic array type from the ARRAY argument, including its rank/kind.
- Independently resolve final query metadata from ARRAY, not SHIFT or DIM,
  including keyword-reordered calls. Declared objects and user-procedure
  bindings remain authoritative.

The interpreter independently checks exact arguments, type/kind, rank-one/two
bounds, SHIFT conformance, DIM and result metadata. Runtime stages the result
with existing budgets and explicit temporary limits. This producer patch does
not implement execution or broaden the interpreter beyond its stated subset.
`test/test_cshift_producer.f90` checks intrinsic and user-shadowed binding/type
metadata directly through the strict, nonstandardizing producer API.
