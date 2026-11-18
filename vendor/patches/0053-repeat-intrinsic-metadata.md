# 0053: REPEAT registration, metadata and procedure shadows

Local MIT-licensed FortFront correction. Register REPEAT with CHARACTER and
INTEGER arguments and infer scalar default CHARACTER metadata independently
of its input metadata. Explicit source function and generic-interface bindings
clear stale intrinsic classification before normal procedure resolution. This
preserves ordinary nonreserved intrinsic names, including REPEAT.

No adapter check is weakened. The interpreter separately checks association,
argument types/ranks, result metadata and cached lengths. Native producer tests
exercise intrinsic calls and scalar/array/result/function/generic shadows;
runtime corruption tests are independent of those producer assertions.

The patch contains only registry and type-query source changes and was made
against the exact final 0.30 vendor tree. Apply with `patch --fuzz=0 -p1` at the
vendor root. Release integration replays this patch after 0052, followed by 0054, with zero fuzz and no offsets. The complete chain reproduces all 457 vendor files byte for byte; the semantic delta remains the same two files.
