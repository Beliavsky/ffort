# 0065: ASSOCIATED default LOGICAL metadata

Apply the matching patch at the vendor/fortfront root with `patch -p1 --fuzz=0`.
The semantic delta was independently validated on certified interpreter 0.37
through vendor 0062 and replays unchanged here after 0063 and 0064. It adds no
registry entry and preserves the intervening intrinsic/import additions.

ASSOCIATED always returns a scalar default LOGICAL. The earlier generic
inference path could inherit REAL(8) or INTEGER(8) operand kind. A dedicated
producer case now fixes type, kind 4 and rank 0 for both arities and keyword
orderings. It does not evaluate pointer state or target values.

The interpreter independently validates the call and designators, including
metadata-only KIND and empty expressions. Six independent producer cases and
adapter/runtime/KIND mutation tests accompany the bounded two-argument feature.
No runtime policy or pointer extension is implemented in the vendor patch.

Reference: J3/18-007r1 section 16.9.16 paragraph 4, printed page 344,
https://j3-fortran.org/doc/year/18/18-007r1.pdf .
