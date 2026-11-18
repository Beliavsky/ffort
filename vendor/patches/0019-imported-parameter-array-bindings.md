# Imported PARAMETER array bindings

The strict explicit-interface validator sometimes lacks USE-associated PARAMETER arrays in its semantic scope cache and consequently mistakes an array element for an external function. Resolve the occurrence to its visible declaration and recognize an array declaration before checking procedure interfaces. Do not accept a name merely because a matching array exists elsewhere in the arena.

The native regression covers direct access, ONLY imports, explicit PUBLIC with module PRIVATE, arithmetic, procedure actuals, and derived constructors. It verifies exact INTEGER(8) values above 2^53 without floating-point conversion. Producer-only negative tests preserve rejection of private arrays, arrays omitted from ONLY, empty ONLY imports, scalar references with subscripts, and undeclared functions.

Validation also includes eight previously failing cross-feature fixtures and exact interpreter/GNU output checks in fresh GNU working directories.
