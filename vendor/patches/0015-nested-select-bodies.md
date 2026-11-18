# Nested SELECT bodies

The pinned FortFront basic statement-body and counted-DO body parsers handed a nested SELECT's header alone to the SELECT parser. Its following CASE statements and END SELECT were then consumed by the enclosing construct, losing nesting and potentially rejecting a valid program at its final END PROGRAM.

`0015-nested-select-bodies.patch` dispatches SELECT CASE/TYPE/RANK on the original token stream before statement slicing, using the existing callbacks in generic bodies and existing parser functions in counted-DO bodies. It also explicitly marks the recursive body dispatch procedures recursive. The change preserves the existing callbacks and AST node types and does not bypass semantic checks.

Regression: `tests/select_case/cases/nested_select.f90` contains SELECT CASE inside SELECT CASE inside DO. Expected output is 11, then 22. The interpreter's independent adapter validates the nested selector expressions, case values, case-chain identity, scoped bodies and exit jumps.
