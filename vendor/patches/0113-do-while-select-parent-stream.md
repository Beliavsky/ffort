# 0113: complete SELECT bodies inside DO WHILE

Apply after 0112 with `patch -p1` in `vendor/fortfront`. This changes only
`src/parser/control_flow/parser_do_constructs_part2.inc`.

A DO WHILE collector previously sliced SELECT at its header, losing CASE bodies
and leaving statements outside their owning SELECT node. The correction uses
the same parent-stream SELECT CASE/TYPE/RANK dispatch as counted DO, appends the
returned node to the WHILE body and resumes at the advanced parser cursor.
The existing completed-body child-parent linkage remains authoritative. It
neither relaxes the adapter nor adds interpreter SELECT TYPE/RANK support.

Reconstructed project-root patch SHA-256:
`ce23f6ad1d942ea1fe71cddb239f598b1d967edd3bbf7c7e213dde6bea8f3137`.
Reconstructed canonical vendor-root patch SHA-256:
`96556322bf07b551eeab6472a802b993773ebfb98a58229a003f0a5eae22a24c`.
Both match retained historical patch identities. Zero-fuzz/zero-offset replay
reproduces source SHA-256
`417da5e412795f7244881b4e2b8db4f10aa76fd53075a38337d2fcd1fa369665`.

The ten independent composition sources retain all original bytes/expectations.
Pre-reset failures and subsequent success remain transcript evidence, not
recreated raw run logs. Fresh candidate execution and full clean release
certification are separate requirements after reconstruction.
