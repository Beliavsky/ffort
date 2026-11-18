# Release 0.42 independent composition checks

This directory is isolated from the integration source and original fixtures. The suite is default-cap specific (1,000,000), not a 10-million or full-utilities certification. Original fixture bytes are never edited or copied into generated cases.

Run `python run_tests.py --candidate /absolute/frozen/fortfront --gfortran /absolute/gfortran --result results.json`. The runner copies and hashes the executable, pins generated source bytes and the manifest, requires silent successful `--check`, status 0 and empty stderr on successes, status 2 and a named diagnostic on runtime rejections, and zero partial output in rejection probes. Numeric output uses exact Decimal comparison with signed-zero preservation; CHARACTER output is byte-exact after lossless UTF-8 decoding. There are no tolerances. GNU uses strict F2008 mode because FORALL is valid in F2008 and otherwise produces an F2018 obsolescence warning; all successful compiler/runtime stderr must be empty.

`test_runner.py` adversarially exercises the runner. Resource-policy, alias, and undefined-value tests compile under GNU but are deliberately not executed there. Their interpreter behavior is not a GNU language conformance claim. In particular, GNU has no interpreter 1-million element or 16MiB character-byte policy. Allocations are bounded; the interpreter gets an explicit 50-million step budget and each process a 120-second timeout. This is not a universal OOM guarantee or stage-specific allocator-failure injection.

`test_release042_storage.f90` is a standalone native test against the public fi_ir module. It checks independent record component/definition ownership, mixed CHARACTER/record arrays, zero-length CHARACTER metadata, deallocation lifetime, payload release upon numeric replacement, zero-product shapes with huge operands, and saturated cap products. Build against fi_limits and fi_ir in a separate temporary/native directory, never using fpm in the integration tree. This public-layout test is separate from runtime mutation safety, which the feature native suites cover.

`prepare.py` reproduces the cases and manifest and updates the runner's manifest pin. Intentional changes must be reviewed and then rerun; generated policy cases are not user originals. Initial GNU-only result is retained to show the corrected F2018 warning policy rather than hide it.

## Preview outcome

All 16 cases pass against merged preview SHA256 35b48d138566046b8037d05bfdfa8369dabc23bb257ec0f4f42c283c720f7342. Five are GNU runtime comparisons and eleven GNU compile-only (including explicit mutable host-length subset rejection). Entry-captured mutable dummy lengths are covered positively; mutable host/module length dependencies are not claimed supported. Native standalone test passes and 39 harness adversarial checks pass. Initial and corrected preflight results document fixture adaptations. No implementation edits were made.

`profile_character.py` separately characterizes nested INOUT copies/reallocation of 16,384 LEN=0/1 elements under Unix 64MiB and 512MiB address-space limits. All four preview probes succeed with empty stderr and exact body/finish output. This does not induce or isolate allocation failures and is not a claim of universal recovery. Deterministic fault injection of argument buffers/implicit payload copies remains outside this deliverable.
