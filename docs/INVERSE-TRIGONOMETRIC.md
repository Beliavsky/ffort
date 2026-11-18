# Bounded real inverse trigonometric functions

ASIN(X), ATAN(X), ATAN(Y,X), and ATAN2(Y,X) support finite REAL(4) and REAL(8)
operands. Results are radians in the input kind. Binary arguments must have the
same kind. Scalar expansion and conformable rank-one, rank-two and rank-three
arrays are supported, including dynamic and empty arrays. Keywords are X for
unary calls, and Y,X for binary calls; keyword order does not change association.
Supported constant expressions can use these functions.

ASIN accepts the inclusive interval [-1,1]. Unary ATAN accepts all finite
representable inputs. Binary ATAN and ATAN2 require at least one nonzero operand;
all combinations of two signed zeros are rejected. The host same-kind ATAN2 is
used directly, without forming Y/X, avoiding quotient overflow and underflow.
The sign of a zero Y is preserved: positive X produces a corresponding signed
zero result, and negative X produces the corresponding signed pi endpoint.
Complex and REAL16 inputs and IEEE nonfinite values remain unsupported.

The source recognizer, independent producer adapter, and runtime validate
argument count, identity, type, kind and shape. Runtime checks validate both
operand trees, literal caches, declared types and cycles, including unevaluated
KIND and empty expressions. Invalid evaluated domains are reported before
calling a host mathematical intrinsic. These names are not reserved: scalar,
array, function-result, procedure and generic declarations retain identity.

ASIN and ATAN were already registered by FortFront. Vendor patch 0074 adds only
ATAN2 to the registry and preserves elemental shape and same-kind metadata for
all three names. It does not claim support for the producer's wider numeric
kinds or complex semantics.

## Original program scope

The focused original-program target is the unchanged M_intrinsics demo_sin,
which computes a great-circle distance with an internal haversine function.
The separate demo_asin also requires named CHARACTER parameter formats, and
demo_atan additionally requires inferred parameter-array bounds. Such later
blockers are not treated as complete-program passes. Source hashes, GNU results
and exact counts belong to the accompanying focused-suite validation receipt.

Primary definitions:
- https://gcc.gnu.org/onlinedocs/gfortran/ASIN.html
- https://gcc.gnu.org/onlinedocs/gfortran/ATAN.html
- https://gcc.gnu.org/onlinedocs/gfortran/ATAN2.html

## Verification

The focused suite includes 222 source cases, including tiny/subnormal inputs,
extreme finite ratios, every quadrant, signed axes, keyword reorderings, arrays,
empty expressions, source shadows, and controlled domain rejections. The native
runtime/adapter suite performs 3,173 assertions, the assignment regression adds
160 assertions, and the producer suite performs 35 cases.
Exact numeric records use Decimal equality and preserve zero signs; mathematical
comparison tolerances, where requested by a fixture, are explicit in its manifest.
The unchanged demo_sin formatted output is byte-exact against GNU 14.2.

Seven pre-existing mathematical suites retain 328 passing source cases. These
focused checks are not presented as a full-language conformance claim. The final
validation receipt separately records clean aggregate-native completion.

The initial implementation passed the 187-program baseline native aggregate.
The subsequent assignment-counter correction is covered by all 222 focused
source cases and all three feature-native tests linked to the corrected library.
Final release-wide aggregate results are recorded by the release verifier.

The merged release verifier selects `--with-named-formats` and requires the full
unchanged demo_asin to execute. Isolated feature evidence is explicitly marked
without named formats; the profile changes no case count and never accepts
both success and rejection for the same fixture.

## Array-assignment counter isolation

Independent release composition found that the new mathematical operand loop
initially used the enclosing execution frame's `j` counter through Fortran host
association. Array assignments could skip elements or exhaust the step limit.
Declaring `j` locally in the numeric evaluator fixes the cause without altering
any resource limit or mathematical result. The maintained three-element module
composition fixture passes unchanged, with byte-exact GNU output at the default
budget. All newly added scratch variables were audited for local declarations.
