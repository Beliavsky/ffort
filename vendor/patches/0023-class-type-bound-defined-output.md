# CLASS/type-bound call and defined-output producer corrections

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. Copyright and MIT license remain in
`vendor/fortfront/LICENSE`. These are local interpreter corrections.

1. The type-binding parser accepts keyword tokens as binding names and retains
   the complete READ/WRITE generic-spec, including `(formatted)`. Previously a
   defined-I/O generic could lose its target because WRITE was a keyword and the
   parenthesized suffix was not consumed as part of the generic name.
2. The explicit-interface checker does not search its ordinary-procedure name
   cache for a type-bound CALL such as `obj%method`. Its interface comes from
   the type binding. Function-form type-bound calls already took the equivalent
   route. This is not acceptance of an arbitrary missing procedure: the
   interpreter's independent adapter resolves and verifies the object, exact
   declaring type, binding, implementation, accessibility and all dummies.
3. `query_type_bound_call` resolves the receiver's declared type in the receiver
   declaration's lexical scope before falling back to the existing generic
   search. This prevents a same-spelled type in an unrelated earlier module
   from providing the wrong method binding.

The CLASS/defined-I/O corpus includes the exact original 205-line date program,
renamed/implicit binding targets and distinct same-named module types. Native
frontend tests verify a valid producer/IR pair and reject 21 independent binding,
CLASS, passed-object, location, dispatch and child-write-control mutations.
No source lowering or native execution backend is introduced.
