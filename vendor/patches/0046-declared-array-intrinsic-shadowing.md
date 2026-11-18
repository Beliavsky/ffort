# 0046: Declared arrays shadow same-named intrinsics

Local MIT-licensed FortFront correction: when canonical resolution has bound a
call-or-subscript node to an explicit array declaration, set its array-access
flag and clear its intrinsic-call flag. The element type/rank already come from
that declaration. This keeps identity, classification and metadata consistent
when names such as INDEX, LEN_TRIM, ADJUSTL or ADJUSTR denote user arrays.

The interpreter adapter retains its exact declaration-identity and call-flag
checks. Four producer-only tests verify the canonical type/kind/rank and flags;
GNU differential tests additionally cover scalar declarations, array indexing,
function result names, user procedures and a named generic.

Apply after patch 0045 using `patch -p1` in the vendor source root.
