# 0057: DIM, SIGN and LOG_GAMMA producer metadata

Local MIT-licensed FortFront correction. Register DIM and LOG_GAMMA; SIGN was
already in the registry. Derive all three elemental result ranks from the
conforming actuals, including scalar expansion when the first argument is scalar
and a later argument is an array. Derive result type and kind from the first
actual instead of the registry's generic REAL description, so INTEGER DIM and
SIGN remain INTEGER and REAL(8) results retain kind 8.

No strict semantic validation is disabled. The interpreter adapter and runtime
separately validate arity, keywords, argument/result type and kind, rank, shape
and slot metadata. Producer tests independently verify scalar and rank1/2/3
metadata and ordinary declared-array/user-function name shadows.

This two-file patch is based on the frozen 0.35 vendor sources through0056.
Apply with `patch --fuzz=0 -p1` at the vendor root. Registry totals must compose
additively with subsequent intrinsic-registration patches.
