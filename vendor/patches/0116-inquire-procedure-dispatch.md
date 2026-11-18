# 0116: retain INQUIRE in procedure statement dispatch

Applies after 0115. The existing main parser recognizes structured INQUIRE, but
the procedure/IF utility dispatcher omitted it and could silently skip the
statement. Add only the existing parse_inquire_statement import and dispatch
case. Keyword-as-variable disambiguation remains before dispatch. No adapter
ownership, NAME target, registered-input or external-effect guard is relaxed.

The first immutable0.54 preview preserved two actual positive failures:
dummy_target and the exact original utility line 2992 harness. Both failed
checking/running at 6:0 with missing statement, while GNU ran them successfully.
The unchanged metadata native also failed its direct-subroutine baseline. An
independent first-library AST probe found main and nested IF nodes present, but
direct procedure INQUIRE absent. A separate native compile error was a test
import mistake, fixed by changing only fortfront_ast to ast_nodes_io.

Source review 733bf294 passed exact replay and scope/dispatch checks. Corrected
second CLI 5c5b0811 with matching archive 711c6281 passes source 36/GNU 36, unchanged
metadata native 325 and import-only corrected producer 140. The first failures
and probe remain preserved in evidence/inquire_name. This is focused validation,
not full release or whole-utilities execution.
