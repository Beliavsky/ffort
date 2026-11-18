# 0050: SHAPE inquiry metadata

The existing SHAPE registry entry is retained. This local change to the pinned
MIT-licensed FortFront source independently resolves SHAPE as rank-one INTEGER,
with default kind 4 or the positional/named KIND source argument. SOURCE's rank
and data type do not become the result rank/type. Reordered keywords are handled
by the same validated KIND-slot helper as other supported inquiries.

Strict semantic analysis is not bypassed. Explicit variable, array, procedure,
result-name and generic bindings continue to shadow the intrinsic.
The interpreter separately bounds SOURCE to intrinsic rank zero through three
and INTEGER result kinds 4/8. Apply after the preceding patches with `patch -p1`
in the vendor source root. Independent producer tests cover seven metadata and
shadowing cases.
