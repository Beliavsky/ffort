# Bounded LGE, LGT, LLE and LLT

Each intrinsic takes exactly two default CHARACTER arguments, positional or named
STRING_A and STRING_B. Both are required. The default LOGICAL result has kind 4
in this interpreter. Wider CHARACTER kinds, optional KIND, alternate keywords,
extra actuals and unsupported argument types are rejected. Intrinsic names are
not reserved: scalar, array, function-result, procedure and generic declarations
continue to bind normally.

ASCII code ordering is used explicitly, not the processor's relational operator
ordering. The shorter operand is compared as though padded with ASCII blank 32.
Empty strings, trailing blanks, significant leading blanks and embedded ASCII
NUL/control characters therefore behave consistently. Every evaluated character
must have ASCII code 0 through 127. Non-ASCII default-character data is an explicit
runtime boundary. Scalars expand against arrays; rank-one through rank-three
arrays must conform. Operand lengths may differ. Each supported CHARACTER value
keeps the existing 65,536-character cap.

The implementation allocates no padded copies. It scans both strings completely,
records the first unequal pair, checks all remaining characters and consumes one
execution-budget unit per compared position. This makes the bounds and repertoire
checks independent of where the first difference occurs. The existing overall
execution, array and output caps are unchanged.

KIND checks the structure and default-kind result without evaluating CHARACTER
contents or user functions. Static and empty paths independently validate arity,
slots, operand/result types and kinds, ranks/dimensions, literal caches, declared
lengths and cycles. A memoized CHARACTER-expression walk rejects indirect cycles
without confusing shared acyclic operands with cycles. All loop and scratch
variables in new helpers are explicit locals.

Source and direct producer tests are separate from public-IR mutation/runtime
checks. Exact original source hashes and upstream license are retained under
[the suite](../tests/lexical_comparisons/README.md). Full-release aggregate
verification is separate from the isolated focused feature runs.

Primary reference: [GNU LLT and lexical comparison semantics](https://gcc.gnu.org/onlinedocs/gfortran/LLT.html).
