#0090: Array-constructor implied-DO producer metadata

Cumulative local MIT-licensed delta after0.45 producer patches through0088.
No intrinsic registrations or AST fields are added. Modern/legacy constructors
parse each ordered value recursively, retaining mixed/sibling/nested DO bodies,
source positions and parent edges. Constructor-only semantic preparation preserves
the inherited INTEGER4/8 declaration type without overwriting outer bindings.
Source-resolved metadata inquiries avoid false own-index value diagnostics.
Type queries derive rank-one element metadata from every loop body value.

Apply at vendor/fortfront with patch --fuzz=0 -p1, once. The interpreter separately
validates its bounded syntax, lexical index owners, types, caches and source
identity. This producer patch does not admit arbitrary Fortran constructors.
