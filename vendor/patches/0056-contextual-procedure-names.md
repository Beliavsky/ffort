# 0056: Contextual PROCEDURE entity and dummy names

Local MIT-licensed FortFront corrections based on the final 0.32 vendor tree
through 0055. Apply at the vendor root with `patch -p1 --fuzz=0`.

Keep PROCEDURE a lexical keyword. Admit it only in these parsed name positions:

- An entity after a declaration's type specification/attributes/separator.
- A standard dummy argument before comma or close parenthesis, without changing
  the existing lazy typed PROCEDURE(interface) parameter path.
- The local or remote entity in USE ONLY/renaming syntax.
- A specific name after the MODULE PROCEDURE header has already been consumed.

The independent guard separately admits the name and existing adapter binding,
argument-count, declaration identity, type, rank and INTENT checks remain active.
No general keyword relaxation, semantic-check bypass or runtime feature is added.
Native tests preserve actual PROCEDURE pointer declarations, MODULE PROCEDURE
and type-bound PROCEDURE clauses. Program-unit names remain outside this patch.
