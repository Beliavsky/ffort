# STOP physical source locations

FortFront normalizes continuation tokens onto the initial logical line for parser statement-boundary handling. Retain the original physical line in token metadata, copy it with tokens, and use it for STOP statement locations. This allows the independent interpreter adapter to match a STOP on a continued single-line IF against its exact physical source line without weakening the statement cross-check.

The derived frontend fixture includes a continued IF/STOP and rejects a mutated STOP instruction location.
