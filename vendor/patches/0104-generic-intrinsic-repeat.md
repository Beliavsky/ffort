# 0104: named function-generic / intrinsic REPEAT coexistence

Local MIT-licensed correction against the implementation-frozen interpreter
0.48 r2 vendor tree. This patch changes only
`src/frontend/frontend_compiler_type_queries.f90`.

After scoped generic-specific resolution yields no matching function, a valid
intrinsic REPEAT call may recover scalar default CHARACTER result metadata.
Matching user specifics keep precedence; ambiguous selection never falls back.
The new matcher independently associates exactly STRING and NCOPIES, rejects
unknown/duplicate keywords and positional-after-keyword actuals, and requires
scalar default-kind CHARACTER plus scalar INTEGER operands. Ordinary procedure
bindings do not enter this generic fallback. Subroutine-generic extension is
outside this deliberately bounded patch, although GNU accepts that language
case. Other intrinsic generic extensions are not added.

The interpreter source guard and adapter separately enforce association,
source-specific priority, types, ranks, and result metadata. This producer-only
patch does not grant executable semantics or alter the intrinsic registry.
Tests: `test/test_generic_intrinsic_repeat.f90` and
`tests/generic_intrinsic_repeat/`. The combined 0.49 preview passes the 39-case
focused source/GNU suite and 23 native producer/adapter assertions. These
focused results are distinct from the full clean release certification.

Apply once at `vendor/fortfront` with `patch --fuzz=0 -p1`, after the existing
0.48 chain (through 0099; reserved numbers need not all have vendor deltas) and
before additive LEADZ patch 0105. The raw 0104 delta is already present in the
REPEAT core patch and must not be reapplied to that tree. The wrapper ledger
installs the raw patch and this note only.
