# Bounded SPACING and NEAREST

`SPACING(X)` and `NEAREST(X,S)` support REAL(4) and REAL(8), scalar and existing
rank1–3 elemental shapes. Conforming array operands and scalar broadcasting use
the existing expression engine. Result type and kind follow X. S may have either
supported real kind independently; only its sign determines direction. Positional
and X/S keyword arguments, including reversed keyword order, are supported.

Operations execute in X's actual precision. Stored REAL(4) values are converted
to REAL(4) before the host operation, not operated on as REAL(8). A mixed-kind S
is reduced to its sign without conversion to X's magnitude range. Very small or
very large REAL(8) directions remain valid for REAL(4) X.

SPACING returns model spacing, not an unconditional IEEE nextafter difference.
At zero, subnormal and sufficiently small normal inputs it returns positive TINY.
At one, spacing is EPSILON; NEAREST toward smaller magnitudes instead moves by
EPSILON/2. NEAREST preserves subnormals and signed-zero approach. Outward steps
from positive/negative HUGE are rejected before calling the host operation,
consistent with the interpreter's finite-result policy. Evaluated S must be
nonzero, including negative zero. Nonfinite arguments are rejected.

Empty expressions retain existing no-element evaluation semantics: structural
metadata is checked, but values with no result elements are not evaluated.
Likewise KIND and numeric-model metadata inquiries do not execute nested values.
This is not permission to supply zero S to an evaluated NEAREST operation.
Undefined, absent, unallocated or invalidly associated data fail through existing
runtime checks when values are required. No IEEE module, nonfinite-value support,
new kind, or changed general arithmetic policy is introduced.

The parser, independent FortFront adapter and runtime each validate argument
count, type/kind, shape and keyword slots. Runtime validation also covers calls
under KIND and empty enclosing expressions. Tests corrupt both X and S descriptors
and independently query producer metadata, including mixed-kind keyword order.

The original M_intrinsics demo_spacing is unchanged and GNU-differentially tested.
GNU Fortran14.2 is a valid-domain oracle; outward infinity and undefined/invalid
input cases are compile-only policy checks. Full M_intrinsics support is not claimed.
