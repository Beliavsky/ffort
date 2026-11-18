# 0096: Case-insensitive allocation option names

Applies after 0095; function and subroutine registries are unchanged.
Normalize comparison keys for STAT, ERRMSG, SOURCE and MOLD in the ALLOCATE
parser and STAT/ERRMSG in DEALLOCATE. Keep original token text, token kinds,
option expressions, variable bindings and string contents unchanged. Contextual
object names continue to be objects unless followed by an equals sign.

The unchanged upstream demo_allocated uses uppercase STAT/ERRMSG. Verification
covers its full execution, mixed-case options in both statements, and uppercase
producer/adapter cases within test_allocation_errmsg. The interpreter's bounded
ERRMSG storage and runtime contract is documented separately.
