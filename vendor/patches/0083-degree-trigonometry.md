# 0083: Degree-trigonometric metadata

Local MIT-licensed producer extension for ACOSD, ASIND, SIND and COSD.
Adds four unique registry identities (110 to114), same-kind REAL results and
conforming elemental rank metadata. No lexer reservation or numerical
implementation is imported into FortFront. The independent adapter/runtime
restrict supported kinds, shapes, source identities and finite domains.

Apply with `patch --fuzz=0 -p1` at the cumulative vendor root after0082.
0081 changes only the statement factory and 0082 changes only the I/O factory;
neither changes either source file in this patch. The main feature core already
contains these raw vendor source edits: do not apply both copies.
