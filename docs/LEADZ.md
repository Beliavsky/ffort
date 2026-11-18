# Bounded LEADZ

LEADZ(I) counts leading zero bits at the declared INTEGER width: kind 4 uses
32 bits, kind 8 uses 64. It accepts one positional argument or the canonical
keyword I=. Its result is default INTEGER (kind 4), even for INTEGER(8) input.
Zero returns the complete width; a supported negative two's-complement value
returns zero. The minimum representable signed value is accepted without ABS,
negation, floating conversion or narrowing an INTEGER(8) value to INTEGER(4).

The operation is elemental for scalar and rank-one through rank-three values.
Its result has the operand's shape, including typed empty arrays. Array sections,
allocatable and assumed-shape actuals, constant initialization, and ordinary
function results retain the existing interpreter limits and effect semantics.

Unlike BIT_SIZE, evaluating LEADZ requires defined operand values and an allocated
array where applicable. KIND(LEADZ(...)) remains a metadata inquiry: it validates
the entire expression structure without reading data or executing an operand's
function body. Zero-sized elemental evaluation does not read nonexistent values;
metadata remains checked even beneath empty expressions or KIND.

Shared integer-bit validation protects operand/result types, exact default result
kind, width, rank/dimensions, declaration/literal caches, irrelevant fields,
invalid indices, cycles and excessive trees. The name remains nonreserved, with
scalar/array/procedure/generic/result shadows covered. Unsupported INTEGER kinds
1/2/16, rank four, direct derived-component operands and BOZ remain outside the
bounded subset. This feature adds no slash format descriptor or other bit-count
intrinsics, nor does it claim those upstream examples complete.

`tests/leadz` retains the exact pinned upstream demo_leadz source and license.
Its seven fully formatted output records must match GNU byte-for-byte. Other
positive cases use independent Python integer bit-length expectations and exact
per-record INTEGER/logical tokens, not numeric tolerance. Record boundaries,
canonical integer spelling and final newlines are significant; only ordinary
horizontal list-directed field padding may vary. Negative source cases, bounded subset
rejections and runtime undefined/unallocated safety cases are distinct. Runtime
safety examples are only compiled, not executed, by GNU.

The source/GNU suite and native public-IR guard test are separate. The corrected
combined 0.49 preview passes 59 maintained source outcomes: 32 executions,
22 exact static rejections and five controlled undefined/unallocated runtime
rejections. GNU provides 39 executions, 11 compile-only safety/subset cases and
nine expected source rejections. All 51 initial source bodies remain unchanged;
seven initial positive expectations mistakenly crossed existing line-length,
rank-three reduction or ordinary-function effect boundaries. Their original
expectations/results are retained, their measured rejection contracts are explicit,
and eight separately named fixtures exercise the supported intended operations.
The original demo remains entirely unchanged. No counter-based exact-once function
effect claim is made; supported array function values and KIND suppression of an
ERROR STOP body are checked independently.

Native validation passes 1,013 public-IR/value assertions, including default-kind,
KIND and empty-array metadata paths. The harness passes 3,773 adversarial checks.
The first combined build exposed a genuine independent-adapter result-kind error
for INTEGER(8) LEADZ; the narrow default-kind correction passes the unchanged
native test. All first-stage failed evidence is retained. These are focused
preview results, not full-release certification.

Reference: [GNU LEADZ documentation](https://gcc.gnu.org/onlinedocs/gcc-14.4.0/gfortran/LEADZ.html)
(Fortran 2008 elemental INTEGER operation; default-INTEGER result; zero maps to
BIT_SIZE of its argument).
