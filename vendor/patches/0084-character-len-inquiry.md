# 0084: CHARACTER %LEN inquiry metadata

Local MIT-licensed producer correction after frozen degree patch 0083.
The existing component-access AST node receives default INTEGER scalar metadata
only when its base is CHARACTER and its component spelling is LEN. Argument-rank
queries use the same distinction so CHARACTER array bases do not leak their rank.
Ordinary derived components named LEN keep their existing resolution path.

No registry entries are added: the cumulative registry remains 114 after 0083.
The interpreter independently admits only a whole default-CHARACTER variable,
checks its source binding and metadata, and lowers the syntax to its guarded LEN
inquiry. This producer delta is not standalone interpreter permission for general
components or suffix forms.

Apply with `patch --fuzz=0 -p1` at the cumulative vendor root after 0083. The
project-root vendor package contains this source delta plus its ledger. Apply the
source delta only once. Independent producer tests cover scalar/rank1–3 and
deferred CHARACTER bases and ordinary derived components.
