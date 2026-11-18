# Bounded DO WHILE

Block `do while (condition)` accepts a scalar default-kind LOGICAL condition.
`END DO` and `ENDDO` close the loop. A construct name may prefix the header and
must match its closing name, for example `outer: do while (i < n)` and
`end do outer`. Existing uniqueness and enclosing-loop rules apply.

The condition is evaluated before every iteration, including after CYCLE.
An initially false condition executes no body statement. EXIT leaves the
selected loop without another condition evaluation. Mixed counted, bare and
conditional nesting, named outer transfers and RETURN retain counted-variable
cleanup and procedure-frame rules. IF and SELECT CASE compose in either nesting
direction, including supported same-line CASE actions.

Conditions use existing expression, intrinsic and procedure contracts. Their
values and function results are not carried over from a prior iteration.
Metadata validation does not read ordinary undefined data or execute condition
functions. Actual evaluation still checks undefinedness and honors PURE/SIMPLE,
shared-storage and procedure-effect restrictions. Logical operands retain the
existing eager evaluation; this feature adds no short-circuit guarantee.

Executed instructions, condition validation/evaluation and nested calls share
the existing step budget. Empty loops and CYCLE paths spend steps. Budget
exhaustion is a controlled runtime error; `--max-steps N` sets a positive limit.
Check mode does not execute loops, and acceptance does not establish termination.
Earlier statements, committed stdout and arbitrary prior function effects are
not rolled back by a later failure.

The independent adapter checks conditional control form, source condition,
construct name and body ownership. Runtime checks include root scalar LOGICAL
metadata and actual payload, header/backedge identity, reachable cached value
tag/kind/shape agreement, CHARACTER literal/PARAMETER allocation and exact
length, graph cycles/depth, and normal effect/value safety rules.

Producer 0111 distinguishes WHILE followed by `(` from a counted iterator named
`while`. Producer 0112 preserves complete nested/named anonymous-main DO slices
and matching closing names. Producer 0113 collects SELECT bodies on the parent
token stream and retains existing completed-body child-parent linkage. These
repairs do not bypass adapter checks or add interpreter SELECT TYPE/RANK support.

DO CONCURRENT, numeric labels, nonblock label-terminated DO, optional-comma
`do, while (...)`, nondefault LOGICAL kinds and named non-DO constructs remain
outside this contract. No new input/output form, CHARACTER gather, procedure
effect permission or resource limit is added.

See [CONTROL-FLOW.md](CONTROL-FLOW.md), [BARE-DO.md](BARE-DO.md) and
[SELECT-CASE.md](SELECT-CASE.md). Focused checks are in `tests/do_while` and
`tests/release051_integration`. Measured results and release certification are
maintained separately. This contract was reconstructed after workspace reset;
its prose identity is new, not claimed byte-identical to the lost manual.
