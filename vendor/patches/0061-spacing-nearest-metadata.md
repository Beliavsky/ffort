# 0061: SPACING and NEAREST producer metadata

Applies at the vendor/fortfront root after0060-model-decomposition-metadata.patch.
Certified interpreter0.36 baseline plus0060 has86 registered intrinsics; this
patch adds SPACING and NEAREST for88. Subsequent0062 ISNAN is separate.

The elemental metadata pass includes both names. A dedicated helper resolves X
by position or keyword, so reversed `NEAREST(S=...,X=...)` preserves X's kind even
when S differs. Both actuals participate in elemental rank inference. No numeric
execution or interpreter policy is delegated to the producer.

The standalone semantic delta is spacing-nearest-vendor-raw.patch (registry82→84).
Do not apply it together with this rebased0061. Source bytes were independently
recreated over frozen0060 and match the integration post0061 snapshot exactly.
The interpreter core independently checks type/kind, count, slots and shapes.

Verification: thirteen independent producer cases cover REAL4/8, ranks0–3,
mixed direction kinds, reversed keywords and user/array shadowing. Full source
and native evidence is recorded in spacing-nearest-result.json. The patch retains
all earlier vendor changes and requires no new dependency.

GNU references: https://gcc.gnu.org/onlinedocs/gfortran/SPACING.html and
https://gcc.gnu.org/onlinedocs/gfortran/NEAREST.html.
