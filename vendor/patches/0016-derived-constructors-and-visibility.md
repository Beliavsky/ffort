# Derived constructors and visibility

This local patch preserves the strict structural frontend cross-check for scalar derived types and generic operators.

- The explicit-interface checker distinguishes a structure constructor from an external function by resolving its name to a visible derived-type declaration.
- USE binding respects PUBLIC and PRIVATE attributes on a TYPE definition, in addition to separate accessibility statements.
- Derived-type nodes retain the TYPE header source location rather than the factory default of line1/column1.
- Module accessibility statements retain operator generic names, including multiple operator entries. Previously a keyword token such as OPERATOR ended parsing, leaving a misleading default PUBLIC statement.

Validation: the exact month-date module compiles through FortFront in strict standard-input mode with semantics enabled. Native adapter tests verify type/component identity, constructors, assignments, operator specific membership and visibility, and implicit function results.
