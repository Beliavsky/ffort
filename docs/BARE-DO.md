# Bounded bare DO

Attribute-free loop control `DO` followed by a statement separator now starts a
bare loop. `END DO` and `ENDDO` end it. The body executes repeatedly until EXIT,
RETURN or STOP, or until a checked execution error occurs. Both ordinary and
named bare loops compose with counted loops, IF/ELSE IF and SELECT CASE.

`CYCLE` starts the next iteration of the selected loop. For a bare loop that
means returning directly to its body, without a synthetic control variable,
termination expression or integer overflow. `EXIT` leaves the selected loop.
Named transfers may leave intervening bare and counted loops. Counted control
variables are released on outer transfers and RETURN exactly as before.

All executed instructions and expression evaluation share the existing step
budget, including calls and elemental invocations. The default is 1,000,000;
`--max-steps` sets a smaller or larger positive budget. Even an empty loop spends
steps at its back edge. A loop that does not terminate returns status 2 with
`execution step limit exceeded`. Check mode validates its structure without
executing it. Acceptance does not establish termination.

## Independent checks

The IR records an explicit bare/counting form. Bare loops must have no symbol
or start/end/step operands; the FortFront tree must independently have no loop
control. Counted loops still require a mutable scalar INTEGER variable. Loop
back-edge identity and matching form, scope, construct name and EXIT/CYCLE
resolution are checked independently. Malformed public IR is rejected at
runtime too; no symbol zero is indexed during bare-loop cleanup.

Vendor patch 0054 corrects bare-DO lookahead before semicolons. It does not
rewrite the user's source or synthesize a counted loop. All other producer
checks remain enabled.

## Boundaries and tests

Conditional DO is separately supported as documented in [DO-WHILE.md](DO-WHILE.md).
DO CONCURRENT, numeric labels, labeled termination and non-DO named constructs
remain unsupported. The existing block-nesting cap still applies.
Malformed names, missing END DO and active counted-variable assignments fail
before output. Bare loops do not make implicit SAVE locals or unsupported
procedure side effects valid.

Run `fpm test --target test_bare_do` and
`python3 tests/bare_do/run_tests.py --candidate PATH --gfortran gfortran`.
The source suite covers plain/named loops, empty and nested bodies, semicolons,
mixed counted-loop transfers, IF and SELECT arms, RETURN cleanup, PURE
ELEMENTAL invocation and default/explicit/shared budgets. Infinite programs are
compiled with GNU but never executed as an oracle. GNU is used only for tests,
not as an interpreter execution backend.

The original utility `str_int` requires bare DO, REPEAT and literal substring
reads together. The independent REPEAT/composition integration fixtures own
that unchanged-source evidence. This feature alone does not claim `str_int`,
full `xutilities`, or whole-library execution.
