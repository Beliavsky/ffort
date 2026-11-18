# Logical reductions, MERGE and DBLE metadata

Local MIT-licensed changes to the pinned FortFront snapshot, authored for the
FortFront interpreter. This is not an upstream release claim.

- Register MERGE and DBLE so strict explicit-interface checks recognize them.
- Preserve elemental array shape for DBLE/MERGE calls.
- Resolve DBLE to REAL(8), and MERGE to TSOURCE's type/kind with the conforming
  actual rank. Associate TSOURCE by keyword instead of assuming source order.
- Resolve ALL/ANY/COUNT DIM result ranks and COUNT's optional KIND separately from
  the LOGICAL MASK kind, including reordered keywords and omitted DIM.

The independent interpreter recognizer and adapter still validate argument types,
shapes, slots and result metadata. No semantic diagnostic is filtered or suppressed.

Integration note: patch paths use the package root (`patch -p1`), consistent with
the other shipped vendor patches. Apply after 0027; line offsets are expected.
