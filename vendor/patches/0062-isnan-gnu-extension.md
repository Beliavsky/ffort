# 0062: ISNAN GNU-extension registry and elemental metadata

Local MIT-licensed FortFront additions rebased for 0.37 after patches 0060 and
0061. Apply the matching patch at the vendor root with `patch -p1 --fuzz=0`.
The cumulative registry count moves 88 to 89. The original isolated feature used
82 to 83; its semantic delta is unchanged. Cumulative replay from the certified
0.36 vendor source reproduces all 457 files exactly.

- Register ISNAN as one REAL argument returning LOGICAL, explicitly described as
  a GNU extension.
- Preserve elemental actual rank and independently return default LOGICAL kind4
  metadata, including for REAL kind8 inputs and keyword calls.
- Keep declared objects and user-procedure bindings authoritative.

The interpreter separately validates source shape, exact type/kind/count and
source binding, then runtime metadata. Its finite-value policy is unchanged.
ISNAN is not claimed to be a Fortran2018 intrinsic; GNU comparisons explicitly
use `-fall-intrinsics`, and a strict-standard probe without it must reject.
Original full quick_sort tests remove the old synthetic ISNAN dependency while
preserving the routine and nested procedures byte-for-byte.

