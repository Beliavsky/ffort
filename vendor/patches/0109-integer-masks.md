# 0109: bounded MASKL/MASKR/SHIFTR metadata

Apply once at `vendor/fortfront` after 0108 with `patch -p1`.
Canonical raw SHA256: `0321349910766db97ade428ce131695e3cd1d3106251e34a406982195c16f903`.
Baseline is certified 0.49 source ZIP SHA256
`ef1970fd7dc152229aafff59149c62886fb70a8de466b54b170003f45c594077`;
the preceding internal-WRITE patch does not alter these two target files.

Registers exactly three intrinsics (127 to 130 unique names). MASKL/MASKR
resolve default INTEGER(4) or constant KIND independently of I. SHIFTR
resolves its result kind from the canonical I argument even with reordered
keywords and an independently kinded SHIFT. Elemental rank propagates through
rank three. No lexer keyword, small-kind implementation or BOZ support is added.
Existing local procedure/generic precedence remains intact.

Parser, adapter and runtime separately validate argument association, result
kind, shape, constant selector and metadata/cache safety. The scalar PARAMETER
cache-kind correction is core-only and is not part of this raw vendor patch.

Corrected combined-preview evidence: 164 focused source/GNU contracts,
5,747 public-IR/value assertions and 10,566 adversarial harness checks passed.
Original MASKL/MASKR stdout is byte-exact to GNU; original SHIFTR remains an
explicit unsupported ISO small-kind/BOZ prerequisite. All initial failed
fixture assumptions and the pre-correction native failure remain preserved.
This is focused feature validation, not full-release certification.
