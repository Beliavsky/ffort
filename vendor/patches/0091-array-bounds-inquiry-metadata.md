# 0091: LBOUND/UBOUND result metadata

Applies after 0090 to the pinned FortFront producer. No registry additions.

Derive ARRAY, DIM and KIND positions independently for positional and keyword
forms. Both inquiries have default INTEGER result, or the requested constant
KIND, and rank one when DIM is absent versus scalar when present. Resolve ARRAY
metadata without treating its element kind as the result kind. Keep source-bound
array/procedure resolution ahead of intrinsic dispatch.

Validation: the independent producer test covers 28 vector/scalar, KIND4/8,
keyword order, rank-three expression and intrinsic-name array-shadow cases.
The full runtime subset and malformed-IR contract are documented separately.
