# Bounded INTEGER bit intrinsics

IAND(I,J), IOR(I,J), IEOR(I,J) and NOT(I) operate at the declared INTEGER
width: kind4 has32 bits, kind8 has64. Binary data operands must have the same
kind. Results retain that kind. Negative values use the supported two's-complement
representation. Operations occur at the declared width before sign extension;
no REAL conversion, ABS of a minimum integer, or signed arithmetic is used to
construct a high-bit result.

BTEST(I,POS) returns default LOGICAL. POS may independently have INTEGER kind4
or8. Each evaluated position must satisfy `0 <= POS < 8*KIND(I)`, including a
kind8 position too large to narrow safely. The range check precedes conversion
to a host index. Invalid positions are runtime errors; no record from the
failing output statement is committed. Undefined evaluated operands fail too.

These five operations are elemental for scalar and rank1–3 operands. Scalars
expand; nonscalar operands must conform. Static and dynamic shapes, array
assignments, sections, array-function results and typed empty arrays are checked.
Zero-sized evaluation does not read scalar operand data; malformed metadata is
still rejected. The existing million-element limit, work budget and output
staging policy are unchanged.

## BIT_SIZE is an inquiry

BIT_SIZE(I) returns a scalar INTEGER with the same kind as I, with value32 or64.
I may be a scalar or rank1–3 expression. Its value, array allocation state,
element definedness, section bounds and function body are not evaluated.
The result remains scalar when expanded within a surrounding array expression,
including empty arrays. Parameter initialization and a named parameter derived
from BIT_SIZE used as a kind selector are covered. This does not broaden the
parser's existing syntax for arbitrary inline kind-selector expressions.

KIND around any of these calls checks structure without reading operand data
or executing functions. The adapter checks canonical formal association and
source identity independently of producer metadata. Public IR is validated for
counts, types, kinds, ranks, dimensions, declaration/literal caches, unrelated
fields and cyclic/excessive trees. Shared acyclic subexpressions remain valid.
The six names remain nonreserved: scalar, array, result, procedure and generic
shadows are tested.

The bounded subset excludes INTEGER kinds1/2/16, UNSIGNED, BOZ literal arguments
and direct derived-component operands. The original bit increment did not add ISO availability imports, DATA or slash
edits. The [TRAILZ/ISO extension](TRAILZ-ISO-INTEGER-AVAILABILITY.md)
adds trailing-zero counts and truthful INT8/INT16/INTEGER_KINDS availability
values, not small-kind arithmetic. Existing slash output support is separate.

## Historical initial bit-milestone upstream profiles

The six complete M_intrinsics sources and MIT license are preserved byte-for-byte
with repository/commit/source hashes in `tests/integer_bits/upstream.json`.
GNU14.2 strictly compiles and executes all six originals.

* `demo_ior` and `demo_not` require this milestone plus B/O/Z formatting.
  The standalone profile expects the exact format rejection. The explicit
  `--with-boz-formats` profile expects full execution and GNU comparison.
  IOR's full records and NOT's binary formatted records are byte-exact; ordinary
  list-directed spacing is normalized without changing tokens.
* `demo_btest` also requires slash edit descriptors. Both profiles retain its
  exact `unsupported PRINT format descriptor` rejection. No full-original gain
  is claimed. Diagnostic copies with B and slash edits removed are separately
  labeled probes, never substituted for the maintained source.
* `demo_iand` remains blocked by DATA/BOZ syntax; `demo_ieor` and `demo_bit_size`
  remain blocked by unsupported ISO INT8/INT16 imports. They are not gains.

Each profile has exactly188 outcomes, with one expected stage per case. The
standalone receipt has126 GNU-agreeing successful executions,38 GNU-matching
source rejections,16 compile-only runtime safety cases,2 compile-only bounded
source rejections, and6 original-source boundary observations. GNU executes
132 references, but the six boundary observations are not execution agreement.
The combined profile promotes only IOR/NOT, and is verified separately on the
merged immutable release executable.

## Verification and oracle policy

The independent Python oracle masks each result to32/64 bits and maps its high
bit to the signed value. The native low-byte matrix independently derives bits
by exact low-byte quotient/remainder arithmetic rather than using host bit intrinsics.
Tests cover high-bit/minimum patterns, adjacent wide integers, negative values,
all bit positions, mixed POS kinds, shape/assignment/empty cases and metadata-only
function/undefined/unallocated paths. The native function-state check verifies
that BIT_SIZE draws no random value and an evaluated array-function operand is
called once. All loop temporaries introduced in the evaluator are explicit locals.

The owner-only official-debug app passes188 focused outcomes,9709 native
assertions,56 independent producer cases,33 runner adversarial tests and832
related source regressions. These are focused receipts, not a full native release
aggregate; integration performs that separately. Exact official FPM debug flags
and binary/source identities are recorded in `tests/integer_bits/validation.json`.
No historical Fortran fixture was changed.

GNU14.2 diagnoses `integer, parameter :: x=not(huge(0))` at compile time because
its result is outside the standard symmetric INTEGER model. The supported
machine-boundary runtime tests exercise the declared-width representation;
this separate retained compile-time probe is not counted as execution agreement
or described as a standard-defined compiler defect. No `-fno-range-check` is
used to disguise it. Ordinary successes retain strict GNU comparisons and exact
integer distinctions, including values beyond binary64 precision. Successful
stderr and check stdout must be genuinely empty, not merely whitespace.

Primary references: [GNU IAND](https://gcc.gnu.org/onlinedocs/gfortran/IAND.html),
[GNU BTEST](https://gcc.gnu.org/onlinedocs/gfortran/BTEST.html), and
[GNU BIT_SIZE](https://gcc.gnu.org/onlinedocs/gfortran/BIT_005fSIZE.html).

## Later integrated slash capability (0.49)

The exclusions above describe this feature at its original checkpoint, not the
complete 0.49 implementation. Bounded slash record editing now composes with
B/O/Z, groups, unlimited formats, colon, positioning and nonadvancing output.
Scalar internal/defined-child reached record advancement remains unsupported.
The unchanged complete BTEST demo passes all 24 records byte-exact with GNU.
Use `tests/integer_bits/run_tests.py --with-slash-formats` for the integrated
B/O/Z-plus-slash profile; `--with-boz-formats` keeps its earlier capabilities.
See [slash tests](../tests/slash_formats/README.md) for limits and evidence.

## Later mask/shift extension (0.50)

[INTEGER-MASKS.md](INTEGER-MASKS.md) adds MASKL/MASKR/SHIFTR without broadening
INTEGER kinds beyond 4/8. Masks default to result kind4 independently of the
count kind; SHIFTR retains I's kind with an independently kinded SHIFT. The
unchanged MASKL/MASKR examples have focused byte-exact executions. The complete
SHIFTR original still requires unsupported small ISO kinds and BOZ features;
using SHIFTR in other passing examples is not a full-original SHIFTR pass.

## Current versus historical prerequisites

The old profile outcomes above are retained observations, not current blanket exclusions. Slash formatting was added separately, including the BTEST prerequisite. ISO availability imports move IEOR/BIT_SIZE beyond import-only rejection but do not make their requested unsupported small-kind operations work. DATA/BOZ and unsupported integer kinds remain boundaries. No new whole-example pass or survey count is asserted here.
