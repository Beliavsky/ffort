# 0121: preflight I/O implied-DO control before speculative AST construction

The I/O parser tried every parenthesized output expression as an implied-DO.
On failure it restored token position but left speculative AST nodes allocated.
For parenthesized intrinsic calls with named arguments, this retained duplicate
keyword-assignment wrappers. The independent frontend adapter correctly rejected
them as unmatched, so ordinary valid queries such as SIZE(ARRAY=a,DIM=1) failed.

Add a nonmutating token preflight before allocating any implied-DO AST nodes.
Only a comma at the outer parenthesis level, outside array-constructor brackets,
followed by an identifier and equals sign makes the existing implied-DO parser
eligible. Nested function keyword arguments, strings and constructors cannot
supply this marker. The existing implied-DO parser still performs all syntax and
semantic validation, including required start/end/step expressions. Its success
path is unchanged.

No arena rollback, AST clone approval, source rewriting or adapter relaxation
is used. fi_frontend.f90 remains byte-identical to the prior preview, including
its unmatched-keyword rejection. The owning module receives an explanatory
comment so FPM rebuilds the include's consumer despite incomplete include-file
dependency tracking.

Validation: 46 compiled-gfortran REPL oracle cases, 28 lifecycle cases, and 14
independent batch producer cases passed. Native test_repl_keyword_producer adds
25 checks across 14 fixtures: correct keyword node counts, real/nested implied-DO,
constructors/strings, malformed controls, and producer-only complex literals.
The complex tests do not claim interpreter support for complex values.
