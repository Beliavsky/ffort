# 0074: Real inverse trigonometric metadata

Local MIT-licensed producer extension after 0073. ASIN and ATAN retain their
existing unique registry entries; ATAN2 adds one entry, taking 106 to 107.
Elemental rank and REAL input kind are retained for ASIN, ATAN and ATAN2.
The separate adapter independently enforces arity, same-kind arguments,
keyword association and nonreserved source identity. No complex or REAL16
interpreter support is implied.

Apply with `patch --fuzz=0 -p1` from the cumulative vendor root after 0073.
The feature core contains the same raw source delta against certified 0.40;
do not apply both deltas to the same tree.
