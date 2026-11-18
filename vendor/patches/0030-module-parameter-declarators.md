# Preserve all initialized module declarators

The module specification parser formerly used the single-declaration entry
point for intrinsic-type declarations. That entry point could stop after the
first initializer, leaving later PARAMETER entities to be interpreted as stray
assignments or references. Route intrinsic-type module declaration statements
through the existing multi-declaration parser and append every returned entity
to the module's declaration list. This preserves dependent initializers and
original source, without source rewriting or skipping strict semantic checking.

The interpreter separately adds scope-owned direct module USE associations.
No producer fallback or implicit global symbol lookup is introduced.

Apply after the existing vendor patches; this file changes only
`parser/declarations/parser_module_structures.f90`. Coverage is in
`test/test_module_use_frontend.f90` and `tests/module_use`, including the original
utility kind module, chained INTEGER/REAL constants, arrays and fixed-length
CHARACTER declarations. The full vendor upstream suite has not been run.
