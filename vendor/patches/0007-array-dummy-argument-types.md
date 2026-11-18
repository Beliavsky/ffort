# Array dummy types in strict argument checking

The pinned FortFront strict argument checker reconstructed a declaration's scalar
base type but discarded its array dimensions. It consequently rejected valid
whole-array actual arguments to assumed-shape dummies. This patch wraps the
base type in one TARRAY layer per declared dimension and resolves identifier
actuals through their declarations for arrays as well as scalars. Declared REAL
kind resolution is preserved. The interpreter independently checks exact rank,
type, kind, shape syntax, and argument definability against the AST.

Scalar array elements recover their element type from the exact bound array
declaration. Sections reconstruct their rank from AST triplets and their
element type from the base declaration. This also handles early strict checking
before an occurrence has any inferred type, and prevents REAL64 sections and
elements from losing imported or named REAL kind selectors.
