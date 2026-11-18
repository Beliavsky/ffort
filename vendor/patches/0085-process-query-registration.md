# 0085: bounded process-query producer registration

Local MIT-licensed producer metadata delta on the complete 0.44 baseline,
including canonical 0082's local internal-WRITE and VOLATILE guards.

GETCWD is registered as an intrinsic **subroutine** and added to the existing
impure-subroutine classifier used by DO CONCURRENT. The subroutine registry
increases from 43 to 44; the function registry remains 114. Standard
GET_COMMAND_ARGUMENT was already registered and is unchanged. There is no
GETCWD function-form support or general external I/O implementation.

The interpreter independently resolves source procedure/generic/data shadows,
associates positional and keyword arguments into fixed formal slots, enforces
PURE/SIMPLE and local-output restrictions, and validates public IR before
execution. This registry entry is not permission to bypass those guards.

Apply with `patch --fuzz=0 -p1` at the cumulative vendor root after 0084. The
project-root vendor package contains the same two source deltas and this ledger;
apply the source delta only once. Exact cumulative source replay is recorded by
the feature verification receipt.
