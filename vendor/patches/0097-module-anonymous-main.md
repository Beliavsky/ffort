# 0097: Module-leading sources with anonymous main programs

Against frozen 0.46 producer source, this changes only `frontend_parsing.f90`.
A source whose first significant token begins a real module is parsed by the
existing program-unit and statement scanners. The lazy mixed-range detector
previously included the first executable statement in a derived declaration
range, making the unchanged user source fail its trailing-token guard.
No token rewriting, diagnostics suppression, intrinsic-registry addition or
result-type metadata change. Non-module-leading LF mixed sources keep their
existing route. A module followed by explicit or anonymous main retains separate
source AST units. Both STANDARD and LAZY tests preserve trailing-junk errors.

The raw patch applies after 0.46; integration must check cumulative replay after
0094–0096 and retain this exact one-file semantic delta. The derived-default
runtime contract is separately described in `docs/DERIVED-DEFAULTS.md`.
