# Scoped named generic explicit interfaces

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. Its copyright and MIT license
remain in `vendor/fortfront/LICENSE`. This is a local interpreter correction.

The strict explicit-interface validator cached named specifics, but not their
named generic. Consequently, even `use m, only: twice` followed by a valid
`twice(x)` was rejected with "No explicit interface". The generic declaration
was already available through FortFront's scoped declaration resolver.

Patch 0022 recognizes `BINDING_GENERIC_INTERFACE` after resolving the reference
at its source AST node, for both function references and subroutine calls.
It deliberately does not put every generic name in the global procedure cache:
PRIVATE, a missing USE, and USE ONLY exclusions must not create accessibility.
Existing derived-constructor, array-reference and ordinary-procedure behavior
is preserved. Overload selection is implemented in the interpreter and checked
independently against interface/specific AST identity and actual arguments.

`test_generic_producers.f90` passes the original source directly to the strict
producer in seven cases: plain USE, USE ONLY, public generic/private specifics,
private generic, exclusion from ONLY, missing import and empty ONLY. No source
rewriting or post hoc suppression of diagnostics is used.
