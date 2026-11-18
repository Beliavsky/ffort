# 0044: Scalar CHARACTER substring rank

Local changes to the pinned MIT-licensed FortFront source:

- Resolve a scalar CHARACTER slice as rank zero from its canonical base type,
  including CALL actuals visited before the substring flag has been inferred.
  CHARACTER array sections continue to derive their rank from range dimensions.

Strict semantic validation remains enabled. The interpreter independently checks
its smaller scalar-base substring contract. The producer regression test checks
scalar/array dummy distinctions, canonical rank, and grouped length metadata.
Apply after prior patches with `patch -p1` in the vendor source root.

Grouped/module declaration length preservation is supplied by patch 0043,
so 0044 contains only the independent scalar-substring rank correction.
