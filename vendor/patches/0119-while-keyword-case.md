# 0119: case-insensitive WHILE header keyword

Applies after 0118. Existing dispatch correctly recognized uppercase DO WHILE,
but the final WHILE-header consumer compared the original token text to the
lowercase word directly. This lost the loop statement in the producer tree,
causing a missing-statement adapter error for `LOOP: DO WHILE(...)`.

Use the existing `to_lower` helper for that keyword comparison only. Source and
token text, including literals/comments, are never rewritten. A documentation
comment in the owning parser module ensures incremental builds notice the
include-file change. No loop execution semantics change.

Regression: `test/test_repl_loop_control.f90` includes uppercase named WHILE,
EXIT/CYCLE and END DO through both parser layers and retained execution. The
independent CLI matrix checks mixed-case forms and literal preservation.
