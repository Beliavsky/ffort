# 0099: bounded INTEGER bit intrinsics

Baseline: certified interpreter0.47.0, FortFront9a5896a plus patches through0097.
0098 is unused (runtime CHARACTER constructor support has no vendor changes).

Registers IAND, IOR, IEOR, NOT, BTEST and BIT_SIZE exactly once; the function
registry grows from120 to126 unique identities, with44 subroutine identities.
Elemental calls resolve conforming rank independently, BTEST returns default
LOGICAL, and BIT_SIZE retains its INTEGER operand kind with scalar result.
A bounded metadata-only BIT_SIZE constant resolver permits parameter-derived
kind selectors without reading operand values. It requires an intrinsic call,
not an array reference, and recognizes only supported INTEGER widths4/8.
Existing identifier/array/function binding precedence is unchanged. No lexer
keyword is added. The adapter/runtime independently enforce type, kind, shape,
formal association, metadata and public-IR safety; producer metadata is not
accepted as executable semantics by itself.

Apply the raw patch once at vendor/fortfront with patch -p1. The wrapper ledger
artifact installs this patch and note only; do not apply the raw delta twice.
