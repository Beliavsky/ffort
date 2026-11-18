# Optional declaration separators

The double-colon separator is optional in a type declaration with no attributes
and no initializer. Examples include `integer i`, `real(8) value`,
`character(len=8) ampm`, `integer a(3), matrix(2,2)` and `type(box) item`.
This applies in main programs, modules and supported procedure locals/results,
including existing bounded automatic arrays/CHARACTER lengths and rank-three
explicit-shape arrays. Mixed use of colon and no-colon declarations is valid.

Attribute-free derived-type headers accept `type name` as well as `type :: name`.
The supported scalar intrinsic component declarations may omit the separator too.
Attributes on a type header still require `::`.

A declaration carrying any attribute (including PARAMETER, INTENT, OPTIONAL,
DIMENSION, ALLOCATABLE or accessibility) still requires `::`. If any entity has
an initializer, the whole declaration needs the separator. Malformed single or
extra colons, missing commas, empty entity lists and unsupported declaration
features remain errors. This does not add standalone attribute statements,
implicit dummy INTENT, SAVE, mutable local initializers or pointer declarations.

The implementation recognizes the original spelling directly. FortFront sees the
unchanged source and independently retains declaration identities, types, kinds,
shapes and attributes. Adapter checks and runtime semantics are unchanged.

The suite contains 29 source cases: 15 GNU-checked executions and 14 GNU syntax
rejections. Native producer/adapter tests compare both spellings and reject
mutated declaration metadata. GNU remains only an independent oracle.

The 599-byte declaration block from the original xutilities `timestamp` routine
is retained byte-for-byte, including CRLF line endings and its explicit PARAMETER
initializer. A deterministic wrapper executes only the declarations and inquiry
checks; it does not claim that the full timestamp routine, DATE_AND_TIME, or the
complete utility library now executes. The original source fingerprint and block
identity are verified by the runner.
