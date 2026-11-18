# 0.50 bounded source/test checkpoint

Whole CHARACTER array-element internal WRITE, MASKL/MASKR/SHIFTR, and numeric rank-three single-vector gathers are included. Producer patches 0108 (DO parent), 0109 (mask/shift metadata) and 0110 (CASE-header body retention) are included only when bound by the final approved snapshot and ledgers. CHARACTER gather is excluded.

The unchanged original full utility remains blocked at 9329:55 by its array storage cap. The authorized one-byte nmax=100000 working copy reaches 2493:24, CHARACTER vector gathering, at the parse stage. Neither is a whole-program interpreter pass; later adapter/runtime validation remains unproven. The full official verifier passed after a harness-only correction, reusing the original compiled cache; this was not a second empty-cache build. See [current verification](VERIFICATION.md) for measured results, both source identities and the preserved first-attempt evidence. Existing record-owned CHARACTER admission is not a global heap or sandbox guarantee. GNU executions, compile-only references, timing observations and independent known-defect validations must remain separately counted.

Current bounded contracts: [element-file WRITE](INTERNAL_WRITE_ELEMENT.md),
[INTEGER masks and shift](INTEGER-MASKS.md), [numeric gathers](ROW-GATHER.md),
and [CASE body retention](SELECT-CASE.md). Rank-two gathering remains row-only;
rank-three numeric gathering admits one INTEGER vector axis with bare colons elsewhere.
MASKL/MASKR default to kind4, while SHIFTR follows I. Full original SHIFTR still
requires unsupported small-kind/BOZ prerequisites. Scalar/element internal files
remain single-record and element files retain derived-output, section, substring
and explicit PURE exclusions. The continued CASE-header location boundary is
retained. No full utility or future CHARACTER-gather support is claimed.
