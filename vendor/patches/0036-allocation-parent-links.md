# Allocation AST child ownership

ALLOCATE and DEALLOCATE factory nodes did not link their targets, bounds, or
option expressions to the statement. Their lexical scope could not be recovered:
strict analysis misread imported module arrays as external functions, and
DEALLOCATE declaration-identity resolution failed.

Link these children to the new statement using the existing arena helper. No
semantic validation is disabled. The interpreter independently checks each
allocation target identity, rank, bound expression and allowed option. Source
coverage includes main/module objects, explicit lower bounds, STAT and nested
calls in tests/allocatables; test_allocatables checks direct IR mutations.

Apply after patch 0035. This is a narrow producer ownership correction, not a
claim that all upstream allocation syntax or semantics are supported.
