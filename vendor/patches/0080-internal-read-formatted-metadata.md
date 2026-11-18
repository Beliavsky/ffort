# 0080: READ formatted metadata

Local MIT-licensed producer correction. The generic READ factory now sets its
existing is_formatted flag from explicit format, runtime format or NAMELIST
presence. Unformatted READ remains false. The parser already retains source
identity for UNIT, IOSTAT and target expressions; this patch adds no syntax,
registry entries, external I/O access or interpreter admission policy.

Apply with `patch --fuzz=0 -p1` at the cumulative vendor root. The interpreter
independently requires list format `*`, scalar CHARACTER variable UNIT, whole
numeric targets and optional IOSTAT. Other producer-capable READ forms remain
unsupported by the interpreter. Eleven direct producer checks cover list-directed,
keyword, explicit-format, runtime-format and unformatted metadata.
