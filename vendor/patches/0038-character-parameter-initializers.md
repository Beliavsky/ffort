# 0038: CHARACTER intrinsic metadata and initializer lookahead

Local compatibility patch against the bundled FortFront source after patch 0037.
The upstream authors are not represented as authors or endorsers of this
interpreter-specific patch. Existing upstream licenses and notices are unchanged.

Register CHAR and ACHAR as CHARACTER intrinsics so executable calls are not
mistaken for undeclared external procedures. The strict metadata query reports
CHARACTER type, default kind 1 or the explicit KIND constant, and elemental
operand rank. Named KIND is located by its keyword rather than position, so
reordered keyword calls retain the correct metadata.

Declaration lookahead previously treated keyword tokens inside parenthesized
calls and bracketed constructors as a new statement. For example, `.true.` in
MERGE or `character` in a typed constructor ended the scan before the comma
between initialized entities. Continue scanning such nested keywords; only
statement-level keywords may terminate the scan. The actual parser and strict
semantic checks still validate the entire declaration.

`test/test_character_parameters_producer.f90` checks CHAR/ACHAR type/kind/rank
independently, including KIND=4 metadata even though the interpreter deliberately
supports only default CHARACTER. It also verifies both entities in declarations
with nested keywords, typed empty constructors and logical literals. The focused
source suite compares interpreter execution with GNU Fortran.

Apply from the interpreter repository root with:
`patch -p1 < vendor/patches/0038-character-parameter-initializers.patch`.
