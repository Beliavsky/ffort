# 0.27 composition checks

Ten source cases combine OPTIONAL CHARACTER, scalar substrings and the new
CHARACTER intrinsics with numeric/logical OPTIONAL arrays and existing
allocatable arrays and FORALL. Seven execute
against GNU and literal expected output; two absent-value safety cases and one
writable-substring boundary have compile-only GNU checks.

`original_body_composition.f90` contains five exact normalized original utility
procedure bodies, with source ranges and hashes checked by the runner. The
module and main driver are new. This is not execution of the complete original
utilities file. Other cases are synthetic.

Two additional cases combine numeric/logical OPTIONAL arrays with CHARACTER
substring and array operations, including absent/present array INDEX BACK.
