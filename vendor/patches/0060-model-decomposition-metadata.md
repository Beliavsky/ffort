# 0060: Model decomposition and ASCII-code metadata

Local MIT-licensed FortFront correction. Registers FRACTION, EXPONENT,
SET_EXPONENT and IACHAR. Elemental ranks follow all data actuals; EXPONENT
returns default INTEGER, FRACTION/SET_EXPONENT preserve X's REAL kind, and
IACHAR honors a supported constant KIND selector. SET_EXPONENT locates the
keyword X explicitly, so reversed I/X ordering cannot determine the REAL result
kind from its INTEGER exponent argument.

No adapter validation is weakened. Independent source-adapter and runtime checks
validate argument association, type/kind, shape, arity, slots and supported
CHARACTER length. Producer tests independently verify scalar and array ranks,
keyword order, explicit array and procedure shadows, and generic identity.

Based on the certified 0.36 vendor tree through 0059. Apply at the vendor root
using `patch --fuzz=0 -p1`. Registry total increases 82→86; later intrinsic patches
must compose their added entries cumulatively.
