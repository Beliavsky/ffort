# 0072: Real ACOS producer metadata

Local MIT-licensed producer extension after0070 (DPROD/TAND/spelling) and0071
(REAL kind metadata). ACOS already has one registry entry, which remains unchanged; cumulative count106
is retained. Elemental rank and REAL operand kind are preserved. ACOS is not made a
reserved keyword, and declarations/procedures with that name retain identity.

The adapter and runtime independently enforce the bounded REAL4/8 contract.
Complex and REAL16 metadata do not imply interpreter support. Apply the matching
patch with `patch --fuzz=0 -p1` at the cumulative vendor root after0071.
The standalone ACOS core patch contains an equivalent raw delta against0.39;
do not apply both raw and cumulative changes to the same tree.
