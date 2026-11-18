# 0067: Real rounding and inverse hyperbolic metadata

Local MIT-licensed addition to the pinned FortFront producer after patch 0066.
The registry adds AINT, ANINT, ASINH and ACOSH (91 entries become 95). Elemental
rank/type metadata preserves the REAL operand. A separate keyword-aware helper
for AINT/ANINT locates A and optional KIND independently of written order,
preserving the operand shape and selected output kind. Existing KIND expression
resolution is reused. No names become reserved and no type support is widened.

Independent producer tests exercise scalar/rank-one/rank-two/rank-three calls,
REAL4/8 results, constant KIND expressions, reversed keywords, and declared
array/procedure/generic shadows. Adapter and runtime validation remains separate.
Apply the matching patch with `patch --fuzz=0 -p1` at the vendor root of certified
0.38 (through patch 0066). Subsequent additive registry patches must retain all
four entries and adjust their cumulative count.
