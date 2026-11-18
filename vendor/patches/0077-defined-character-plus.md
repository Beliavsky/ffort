# 0077: Defined CHARACTER plus and optional named-generic metadata

Local MIT-licensed bounded corrections after 0076, against frozen 0.42.
The three changed producer files are frontend_compiler_type_queries.f90,
semantic_binary_ops_core.f90 and semantic_analyzer_infer_type_locals_part2.inc.
STANDARD mode retains the exact CHARACTER + operator; lazy-mode helper behavior
stays unchanged. Binary + with a CHARACTER actual selects a visible defined
specific and copies its declared result. Numeric addition is untouched.

Named generic calls may omit only source-declared OPTIONAL dummies, with exact
positional/keyword mapping, type/kind/rank matching and ambiguity checks.
Operator matching explicitly disables optional omission and requires all operands.
This is needed by unchanged char_plus_int -> str(i) -> original str_int with
omitted ndigits/prefix. No helper is replaced. The registry remains 107 names.

Apply with patch --fuzz=0 -p1 from the cumulative vendor root. The core delivery
also includes these raw vendor file changes; do not apply both raw copies to the
same tree. Full scope and tests are in docs/CHARACTER-PLUS.md. Later 0078 touches
the same query file and must retain this earlier semantic delta when rebased.
