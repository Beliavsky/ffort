# 0041: FORALL statement spans, dispatch and header metadata

Local compatibility patch against the bundled FortFront source after 0039.
It is independent of the allocatable-CHARACTER changes in 0040; the release
applies 0040 then 0041. Upstream attribution and licensing remain unchanged.

- The statement-span scanner distinguishes a single-line FORALL statement from
  a construct, so an inline statement does not swallow following IF arms.
- Procedure bodies dispatch FORALL to the same parser as main-program bodies,
  with correct complete-construct spans. Fallback callbacks cover other bodies.
- Header bound/stride/mask expressions retain their parent links and receive
  semantic inference, so array references resolve against their declarations.
- Inline assignment locations after continued headers use preserved physical
  source lines instead of normalized logical lines.

The interpreter continues to independently match exact indices, expressions,
body assignment order and bindings against the resulting AST. It does not
fabricate absent nodes or weaken array-binding agreement.

`tests/forall` and `test/test_forall.f90` cover these producer paths together
with the independent adapter/runtime. Apply from `vendor/fortfront` with
`patch -p1 < ../patches/0041-forall-construct-metadata.patch`.
