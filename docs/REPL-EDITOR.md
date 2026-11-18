# Bounded source editor

`.list` numbers editable body lines from 1. The generated PROGRAM, IMPLICIT NONE
and END PROGRAM lines are shown without numbers and cannot be edited.
`.list -n` prints the exact plain wrapped source, without executing anything.
This body-relative numbering deliberately differs from ofort's effective-source
listing because this preview owns a fixed wrapper.

- `.del n` removes one line; `.del n:m`, `.del :m`, `.del n:` and `.del :`
  remove inclusive ranges. Open bounds mean the first/last body line.
- `.ins n text` inserts before line n; N+1 appends. An empty body accepts n=1.
- `.rep n text` replaces existing line n.

Numbers are unsigned positive decimal integers. Insert/replace require nonempty
text separated from the number by whitespace. Text is source, never a nested
REPL command. Edits accept incomplete drafts without compiling or executing.
Invalid commands, bounds, allocation or resource limits leave source and state
unchanged. Existing 4096-byte line, 10000-body-line and 1 MiB wrapped-source
limits apply; command input itself is also limited to 4096 bytes.

A successful edit discards retained state. If this body has already executed
(or failed during execution), queries and `.vars` are blocked until a successful
explicit `.run` (or `.`), or `.clear`. Assignments and PRINT entered meanwhile
are buffered, not executed. Declarations can be changed while rebuilding.
Even a text-identical replacement invalidates state conservatively.

A failed compile/run does not clear this gate, including STOP with status zero.
A successful non-scalar run still has the existing nonresumable-session limit.
`.load` preserves an existing edit gate; loading an ordinary ungated session
retains its prior source-only reset behavior. Failed loads preserve the gate.
`.save`, `.quit`, `.quit!`, EOF and listing never execute edited source.

This explicit rebuild rule intentionally avoids ofort's implicit replay after
editing executed source. There is no undo/history, rename or auto-END support
in this bounded increment.
