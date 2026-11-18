# ELSE IF, EXIT/CYCLE, counted, bare and conditional loops

The interpreter supports block IF chains with any number of `else if (...) then`
or `elseif (...) then` arms, optional ELSE, and `end if` or `endif`. Conditions
must be scalar LOGICAL. Arms run in source order, and no later condition is
evaluated after an earlier true condition. Empty arms and nested constructs are
supported. Single-line IF admits EXIT/CYCLE as action statements.

Counted DO accepts scalar INTEGER kind 4 or 8 variables and INTEGER bounds and
steps of either supported kind. The controls are evaluated once, converted to
the variable's kind with checked narrowing, and frozen for that loop entry. A
missing step is one. Positive, negative, zero-trip and nested loops retain the
usual final control-variable value. A zero step is a runtime error.

`exit` terminates the innermost active DO without incrementing its variable.
`cycle` proceeds to a counted DO's checked increment and termination test, or
restarts a bare DO body. For conditional DO, CYCLE returns to the condition;
an initially false condition executes no body. See [DO-WHILE.md](DO-WHILE.md)
for conditional loops and [BARE-DO.md](BARE-DO.md) for bare loops. Named
counted loops use `outer: do i=...` and `end do outer`; `exit outer` and
`cycle outer` can target an enclosing loop through IF, SELECT CASE or other DO
constructs. Leaving multiple loops releases every intervening active loop
variable. CYCLE keeps the target loop active. Named loops require a matching
END DO name, and construct names must be unique within the procedure or main
program. Names may be reused in distinct procedures.

## Safety and boundaries

- Active DO variables cannot be redefined by nested loops, assignments or
  writable procedure arguments. The existing checks also apply to kind 8.
- Increment arithmetic is checked at the variable's kind, including the final
  increment. A signed overflow is an explicit runtime error, never wrapping.
- The runtime compares the frozen bound after each checked increment. It does
  not form `last-first+step` or an overflowing signed trip count. Full-int64
  ranges can therefore be entered safely and left with EXIT. Very long loops
  remain subject to the shared instruction budget.
- Out-of-range conversion from INTEGER(8) controls to an INTEGER(4) variable
  is rejected rather than silently wrapping. These are safety policies, not
  claims that every compiler diagnoses the same source.
- DO CONCURRENT, numeric statement labels, optional-comma DO WHILE syntax and
  labeled DO termination remain unsupported. Named IF/SELECT/BLOCK constructs and EXIT
  from non-DO constructs remain unsupported. Invalid or unsupported source is
  rejected before any program output.
- The syntax guard reserves ELSEIF, ENDIF, ENDDO, EXIT and CYCLE alongside its
  earlier statement names. Fortran itself does not reserve these names.

## Independent frontend agreement

The pinned producer previously stored only the first statement of each ELSE IF
arm. Patch 0026 preserves the complete ordered body and links its condition and
all body roots to the containing IF. Its public `parse_elseif_block` return
convention is retained; optional outputs expose the complete body. The adapter
checks every condition and statement, named DO identity, and the exact enclosing
loop/destination of EXIT/CYCLE. The runtime separately validates DO back edges,
scalar control operands, active transfer targets and transfer destinations.

## Verification

Run:

```
fpm test --profile debug
python3 tests/control_flow/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The focused corpus has 57 cases: 26 successful strict GNU Fortran comparisons,
two explicitly specified full-int64 range cases, 24 pre-output source rejections,
and five runtime safety errors. INTEGER output comparisons are exact rather than
converted to floating point. Coverage includes all ELSE IF arms, multiple and
empty arm bodies, condition evaluation order, nested/named transfers across
three loops and SELECT CASE, zero trips, frozen controls, mixed kinds, bounds
near both signed-int64 limits and narrowing/final-increment failures.

The utility fixtures retain the original `first_pos_ge_int`, `first_pos_ge_real`,
`elu_smooth` and `factorial_long` routine bodies. Drivers cover empty searches,
all ELU branches and factorial inputs through 20. Native tests add adapter/runtime
baselines plus 26 malformed-IR rejection cases. Earlier ELSE IF and wide-DO
boundary fixtures are now successful GNU comparison cases. Full utility-module
execution is not claimed; unrelated limitations remain.

Named-DO slicing regressions also cover loops directly inside THEN, ELSE IF, ELSE
and SELECT CASE arms, including procedure scope and inline EXIT/CYCLE actions.
