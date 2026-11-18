# 0064: ERFC_SCALED registry and elemental metadata

Local MIT-licensed producer additions, originally verified against certified 0.37
through 0062 and replayed for 0.38 after 0063. Patch 0063 changes a separate file,
so this matching patch applies unchanged at the vendor root with
`patch -p1 --fuzz=0`. The registry count moves from 89 to 90; all earlier producer
changes are retained and the cumulative vendor replay is checked independently.

Register ERFC_SCALED as a Fortran 2008 one-REAL-argument intrinsic with REAL result.
Canonical frontend queries independently preserve the actual kind and elemental
rank. Existing declared object/function/generic binding precedence remains.
The interpreter separately validates exact source binding, type/kind/count/shape,
empty/KIND paths and finite-domain execution; no producer checks are disabled.

Numerical evaluation is an interpreter change, not a producer approximation.
It uses guarded split-exponent reflection and a large-positive asymptotic tail
to avoid GNU 14 runtime's premature overflow and loss of subnormal answers.
The unchanged M_intrinsics example, independent mathematical references and
explicit GNU discrepancy records are documented in docs/ERFC-SCALED.md.
