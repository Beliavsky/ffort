# 0059: Vector-row metadata and inline IF physical action locations

Local MIT-licensed FortFront corrections rebased against the 0.36 integration
vendor tree after patches 0057 and 0058. Apply the matching patch at the vendor
root using `patch -p1 --fuzz=0`. Cumulative replay from the certified 0.35 vendor
source reproduces all 457 files exactly. The semantic delta is unchanged from
the independently tested feature patch.

- Restore inline-action tokens' physical source lines before parsing the action.
  This uses the physical_line data already preserved by0017, analogous to the
  existing WHERE/FORALL action correction. Continued filter predicates then map
  to the correct unchanged source line in independent adapter matching.
- Count a non-range rank-one INTEGER selector as a result dimension in semantic
  slice analysis and preserve its known extent.
- Use the same dimension rule in canonical frontend slice type queries and in
  strict user-procedure actual-rank checking. Mark the slice query RECURSIVE
  because querying a selector expression may re-enter it.

These metadata corrections do not authorize general vector subscripts. The
interpreter's guard admits only the documented read-only numeric matrix row
form, independently matches the AST, and validates the runtime descriptor.
Original sources and the resource cap remain unchanged. Native tests verify
producer rank/type and continued inline-action locations; direct user actuals
and the complete original filter dependency closure are GNU differential tests.
