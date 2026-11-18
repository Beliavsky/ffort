# 0048: SCAN and VERIFY metadata

Local changes to the pinned MIT-licensed FortFront source register SCAN and
VERIFY and derive their elemental rank and INTEGER result kind from the source.
The shared character-search signature has STRING, SET, optional BACK and optional
KIND. Positional KIND is fourth; named KIND may be reordered or omit BACK.

These changes extend the existing INDEX metadata path without bypassing strict
semantic analysis. Ordinary source bindings shadow the two intrinsic names.
The interpreter separately bounds rank to zero/one/two, result integer kind to
4/8, and CHARACTER/LOGICAL operands to their supported default kinds.

Apply after the preceding patches with `patch -p1` in the vendor source root.
The independent producer test covers 18 metadata and shadowing cases.
