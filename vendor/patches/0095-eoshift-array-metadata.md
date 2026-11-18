# 0095: EOSHIFT registration and ARRAY metadata

Applies after 0094 to the pinned FortFront producer. The independent 0094
BACKSPACE procedure dispatcher and 0097 source scanner do not touch these files.

Add exactly one EOSHIFT function identity, increasing the function registry from
119 to 120 while retaining 44 subroutine identities. EOSHIFT preserves the ARRAY
argument's type, kind and rank. Reuse the existing keyword-aware CSHIFT metadata
helper, which locates ARRAY independently of the actual-argument source order.
Source-bound arrays, functions and generics remain resolved before intrinsic
metadata dispatch; EOSHIFT is not a reserved source name.

Validation: ten independent producer checks cover INTEGER4/8, REAL4/8, default
LOGICAL/CHARACTER, ranks one/two, reordered ARRAY/SHIFT/BOUNDARY/DIM keywords, and
array/procedure shadows. The bounded interpreter contract, runtime checks and
unchanged original demo evidence are documented in docs/EOSHIFT.md.
