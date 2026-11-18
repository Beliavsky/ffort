# 0108: retain completed DO-body ownership

The producer creates counted DO and DO-WHILE-representation nodes before parsing
their bodies, initially with an empty body. Its later body_indices assignment
previously omitted the parent links that push_do_loop/push_do_while establish
when given a complete body at construction. The scope-aware type resolver then
could not resolve a main-program WRITE unit inside such a loop: the unit's
parent was WRITE, but WRITE's parent was zero. The adapter correctly rejected
that unresolved array reference.

After installing each completed body, invoke link_children_to_parent using
that exact owning loop node. This restores the normal factory invariant, not
an inferred parent from spelling or line proximity. Independent declaration
identity and adapter array-classification checks remain unchanged. Counted and
bare-DO interpreter cases are covered; the producer-only DO WHILE regression
does not claim that the interpreter's source guard now supports DO WHILE.

Apply this raw patch once at vendor/fortfront after the certified 0.49 chain
(through 0105) and before 0109/0110. It changes one import and two include-file
completion sites. No formatting/runtime semantics or supported scope is added
by this producer patch. Tests are test_internal_write_loop_parents.f90 and the
focused internal_write_element loop cases.
