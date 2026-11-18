# 0088: Numeric TRANSPOSE and NORM2 metadata

Local MIT-licensed producer delta after process query 0085 and lexical comparison 0086. Number 0087 is unused. Function registrations increase from 118 to 119 by adding NORM2; TRANSPOSE was already registered. The 44 subroutine registrations are unchanged.

TRANSPOSE resolves its MATRIX actual, including keyword syntax, and preserves the resolved element type, kind and rank. NORM2 uses reduction result metadata, preserves the REAL input kind and removes DIM when supplied. Its standard first formal is X, including reversed DIM/X keyword order. Existing reduction, lexical, process-query and ordinary user-binding resolution remains intact.

The interpreter independently restricts TRANSPOSE to rank-two INTEGER/REAL kinds 4/8 and NORM2 to REAL kinds 4/8, rank one through three. This producer patch alone does not admit all Fortran intrinsic forms or loosen source validation. Independent producer tests cover both kinds, NORM2 ranks/DIM and keywords, and ordinary array/procedure name shadowing.

Apply `patch --fuzz=0 -p1` at the cumulative vendor/fortfront root after 0086. The project-root package also installs this ledger and its explanatory note. Do not apply the source delta twice. This cumulative patch replaces, rather than follows, the standalone 0.44-based raw matrix/norm delta.
