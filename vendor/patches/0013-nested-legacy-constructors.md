# Nested legacy constructors

Pinned FortFront commit: `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.

A legacy constructor used as an item of another constructor, for example
`[1,[2,3],(/4,5/)]`, was first attempted as an implied-do. That speculative
parse treated the opening slash as a binary operator without a left operand.
Although the parser subsequently rewound and successfully parsed the nested
constructor, the malformed speculative node remained in the arena. The strict
frontend reported success but the independent interpreter adapter correctly
rejected the incomplete AST.

This patch excludes a leading `(/` from implied-do speculation in both modern
and legacy constructor parsing. Actual implied-do and parenthesized expression
handling remain unchanged. No malformed AST accommodation was added to the
adapter. `test_constructor_producer` checks successful STANDARD/STRICT semantic
analysis and complete binary nodes for nested modern/legacy combinations and an
ordinary parenthesized expression. `test_mean_features_frontend` exercises the
same nested constructors through the independent adapter.

Apply after patches 0001–0012 with `patch -p1` in `vendor/fortfront`.
