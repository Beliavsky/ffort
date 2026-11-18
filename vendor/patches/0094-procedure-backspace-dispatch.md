# 0094: Preserve BACKSPACE in procedure bodies

The shared simplified procedure-body statement dispatcher previously omitted
BACKSPACE, although the independent top-level/block dispatcher already parsed
it. Add the existing parser to the procedure path. No AST representation or
intrinsic registry changes. Keyword-as-identifier disambiguation remains first.

The initial standalone producer probe retained no BACKSPACE node for a direct
procedure-body line. The corrected producer and interpreter source adapter now
agree for direct nested calls, while ordinary source binding and effect checks
remain mandatory. The interpreter executes only explicitly bound in-memory
input-unit tables, not native units or source-requested paths.
