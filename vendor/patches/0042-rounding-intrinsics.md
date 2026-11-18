# 0042: Rounding and LOG10 metadata

Local changes to the pinned MIT-licensed FortFront source register LOG10 and
preserve elemental REAL input kind and shape. NINT/FLOOR/CEILING already exist in
the registry; their canonical metadata now derives INTEGER result KIND rather
than inheriting REAL input KIND, and handles KIND= before A= correctly.
Strict semantic validation is retained. The interpreter separately enforces its
REAL(4/8), INTEGER(4/8) and scalar/rank-one/rank-two boundary.

Apply after the prior patches with `patch -p1` in the vendor source root.
