# Scalar CHARACTER derived components

Supports scalar default-kind fixed CHARACTER components with constant explicit lengths
0:65536 (including named constants), defaults, positional constructors, whole-object
copying, component assignment with padding/truncation, and metadata-only LEN.
Array, pointer, allocatable, polymorphic/PDT components and component-substring
assignment remain outside this feature. Direct KIND(component) remains a tested
runtime boundary; LEN is metadata-only. Undefined data reads still fail.

The named `max_derived_character_bytes` in `fi_ir.f90` defaults to 16 MiB. Runtime
preflight conservatively reserves eight payload slots per derived symbol/expression
and repeated derived operand edge, two per type default cache, and multiplies by
call depth plus two. Ordinary CHARACTER expressions/arrays retain existing limits.
The cap is a conservative admission bound for record-owned payloads, not exact
process heap usage or a global heap/sandbox guarantee. Output staging separately
charges record-owned CHARACTER bytes against its existing 16 MiB limit. Rebuild after changing it; diagnostics name the constant.

34 pinned source cases: 26 GNU executions, 3 invalid-source GNU rejections, 5 GNU
compile-only boundaries. The recursive reservation case intentionally does not run
GNU as its semantics succeed there; FortFront reports its bounded storage limit.
Text records are byte-exact. Only explicitly listed numeric/logical records permit
field padding while requiring exact finite Decimal values or T/F tokens.

Run `python3 test_runner.py` then `python3 run_tests.py --candidate PATH --gfortran PATH`.
