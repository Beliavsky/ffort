# Module-function producer corrections (0.6.0)

Patch `0003-module-function-arguments-and-semicolons.patch` makes four narrow
changes to the pinned FortFront source. These changes do not suppress diagnostics
or modify source text before parsing.

- `semantic_function_call` no longer refines a resolved array reference's
  declared element type using its subscript types as function arguments.
- `semantic_call_signature_collector` does not collect procedure signatures for
  resolved array references. Previously this pass also overwrote a REAL element
  type with INTEGER based on its subscript, causing the strict argument checker
  to reject valid scalar REAL array elements passed to a REAL dummy.
- `parser_block_statement_utils.locate_single_line_end` terminates a procedure
  statement slice before a semicolon operator, rather than swallowing every
  statement on that physical line. String-literal semicolons are not operators.
- `parser_procedure_definition_bodies.parse_procedure_body` consumes semicolon
  separators between statements, including consecutive separators. The existing
  trailing-token rejection still checks each individual statement.

The strict dummy/actual argument checker itself is unchanged. Independent
producer probes accepted the module array-element and semicolon-scope corpus
cases, quoted semicolons, and consecutive separators. Negative probes retained
type-mismatch errors in both directions (INTEGER element to REAL dummy and REAL
element to INTEGER dummy), and retained the syntax diagnostic for junk following
a declaration before a semicolon. GNU Fortran accepted the positive probes.
These are targeted fixes, not a claim of general upstream array-rank correctness
or full Fortran semicolon grammar coverage.
