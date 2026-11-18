# 0068: ERF and elemental Bessel producer metadata

Local MIT-licensed producer additions in cumulative release order after patch0067.
This delivered patch applies at vendor/fortfront with `patch -p1 --fuzz=0` and
changes registry95→102, retaining all four0067 additions. The isolated development
patch used the frozen0.38 baseline (91→98); that input and its hash are retained
in the integration evidence, while this ledger contains the rebased delta.

Register ERF, BESSEL_J0/J1/JN/Y0/Y1/YN. Canonical queries independently propagate
REAL type and X's kind, and merge elemental argument ranks. JN/YN X is positional
argument2, or the X keyword in either actual order; N's INTEGER kind never becomes
the REAL result kind. Object/procedure/generic source bindings retain precedence.

Interpreter admission, source/type/kind/shape checks, two-argument JN/YN scope,
bounded numerical domains and finite-value policy are separate core checks, not
producer approximations. See docs/ERF-BESSEL.md for limits, unchanged original
examples and independent mathematical/GNU validation.

Integration context: this delta replays after 0067 on the 0.38 vendor snapshot; the combined registry grows from 95 to 102. It preserves all four rounding/inverse-hyperbolic entries.
