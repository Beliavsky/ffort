# 0082: WRITE formatted metadata

Local MIT-licensed producer correction. The generic WRITE factory sets its
existing is_formatted flag from explicit format, runtime format or NAMELIST
presence, matching the READ factory correction in 0080. Unformatted WRITE
remains false. No syntax, registry entries, type-query changes or external I/O
permissions are added.

Apply with `patch --fuzz=0 -p1` at the cumulative vendor root, after 0081. Its
ast_factory_statements.f90 child-parent correction is in a different file, so
this ast_factory_io.f90 delta is unchanged. The interpreter independently checks
source bindings, scalar CHARACTER format descriptors, unit/control ordering
and the bounded literal ADVANCE contract; broader producer forms remain outside
interpreter admission. Registry count stays 110 before companion 0083.

## Pre-existing PURE internal-file classification correction

Composition exposed an independent pre-existing defect: the producer rejected
all WRITE nodes in directly nested PURE procedures, including valid internal
files. The certified0.43 minimal reduction rejects identically; the formatted
flag did not cause this behavior. The shared purity classifier now resolves the
exact declaration and admits only a directly local, explicitly declared scalar
writable CHARACTER file. Constant/INTENT(IN), saved/initialized, pointer,
VOLATILE, host/use-associated, unresolved and external-unit targets remain
rejected. Other producer purity checks and all interpreter checks are retained.
READ is unchanged. Scope-unresolved local writes (including the documented DO
fixture) remain bounded rejections, never a fallback global-name match.

See tests/pure_internal_write for strict GNU execution/rejection evidence and
direct producer negatives. The historical PURE and SIMPLE internal-I/O cases
are promoted without source changes; existing SIMPLE oracle limitations remain
explicit. Canonical0082 now touches two independent producer files, still with
no registry or type-query changes.
