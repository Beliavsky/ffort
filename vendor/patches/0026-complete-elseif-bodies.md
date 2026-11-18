# Preserve complete ELSE IF bodies

The pinned parser reduced each ELSE IF arm to a condition/first-statement pair.
It parsed subsequent statements into the arena but omitted them from the IF body
and parent links, losing their procedure scope and executable ownership.

This patch stores each arm as the existing `elseif_wrapper_t` with all ordered
body indices, including an allocated empty body. Conditions and every statement
root are linked to the containing IF. The public two-index return convention of
`parse_elseif_block` remains compatible; optional full-body and parent arguments
are used by the block parser. No semantic-validation fallback is added.

Apply after patch 0025. `test/test_control_flow.f90` and
`tests/control_flow/run_tests.py` cover complete/empty/multiple/nested arms,
procedure scope, condition evaluation order, and adapter disagreement rejection.
The unchanged `elu_smooth` routine is an end-to-end producer regression.

These local changes are separate from upstream FortFront; its MIT notice and
pinned revision remain in THIRD_PARTY_NOTICES.md.

The statement slicers also recognize `name: do` as a complete DO construct,
including its END DO name. Previously IF and CASE bodies sliced named loops
after the header, desynchronizing on a later END IF. A shared named/bare opener
detector covers both IF body paths and generic CASE-arm bodies. The regressions
`named_do_branch_bodies` and `named_do_procedure_elseif` compare directly with GNU.
