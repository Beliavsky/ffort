# Descriptor-known CHARACTER constructor lengths

Both `[items]` and `(/items/)` now accept untyped default-CHARACTER constructors
whose scalar/rank-one items have matching descriptor-known runtime lengths.
Supported length sources are whole assumed/deferred-length variables,
array elements and rank-one sections (length independent of their subscripts),
concatenation of supported lengths, and nested constructors/implied-DO bodies.
Existing fixed-length forms and typed fixed-length padding/truncation remain.

This is not general value-dependent length inference. Nonconstant TRIM,
dynamic substring bounds, dynamic user-function result lengths and other
unrecognized runtime-length calls remain checked source rejections. Wider
CHARACTER kinds, rank-two/three constructor leaves and runtime typed-constructor
length specifications are not added.

## Evaluation, empty results and safety

The constructor's element length is resolved and frozen before its loop controls
or values are evaluated. Every untyped ac-value must agree, including values
within zero-trip bodies and empty arrays. Actual emitted strings are checked
against the frozen length. An explicit typed constructor retains its existing
padding/truncation rules. Per-statement, per-iteration and procedure-activation
cache invalidation also clears this length snapshot; recursive/independent
executions do not share it.

Length inquiries traverse metadata, not the CHARACTER contents or implied-DO
controls. Thus undefined contents can supply a known length to an empty
constructor. Dynamic lengths require a present, valid descriptor: an absent
OPTIONAL or unallocated deferred-length descriptor still reports a controlled
error even for zero iterations. Fixed and assumed length parameters do not require allocation
for metadata-only LEN, including runtime-fixed local lengths and assumed-length
allocatable dummies receiving present but unallocated actuals. These frozen type
parameters are distinct from genuinely deferred CHARACTER(:) lengths.
An inquiry needing the actual shape/data of an unallocated object still fails.

Zero contributed values produce a rank-one array of size zero, preserving its
known element length rather than silently substituting zero. Significant trailing
blanks and zero-length elements are retained. Assignment/output retain existing
staging-before-commit rules; this does not roll back arbitrary user-function
side effects. No new file access or process effects are introduced.

The parser, strict independent source adapter and source-free runtime validate
static/dynamic length caches, declared binding identity, body/control ownership,
type/kind/rank and cycles. The only dynamic cache sentinel is -1, and only the
explicit descriptor-known expression subset may carry it. New scratch-length
validation reports allocation failure instead of dereferencing missing storage.

Limits remain 65,536 characters per value, 16 MiB staged constructor CHARACTER
data, the configured element/live-storage caps (default 1,000,000), eight nested
implied-DO levels, 64 body items per loop, bounded expression traversal and the
unchanged shared execution budget. No global cap or default budget is raised.

## Original utility coverage and next boundary

Eighteen wrappers preserve original CRLF bodies from the retained xutilities:
`repeat_char` (lines 1041–1048), `repeat_char_vec` (1089–1101) and its original
`present_and_false` dependency (1410–1418). Positive/zero/negative repeat counts,
zero-length elements, empty inputs, trailing blanks and all optional alternate
branches execute against GNU with byte-exact output. These are unchanged
procedure closures with synthetic callers, not whole-library execution.

The original full source remains byte-identical. Its separately authorized
working version changes only nmax=10**8 to nmax=10**5. In the isolated constructor
checkpoint it passed the former 1047 gate but stopped at 1192:18, `Unknown or inaccessible subroutine:
system_clock`, in `init_wall_time`. At that checkpoint, both check and explicit 100-million-step run
exited 1 during source checking with empty stdout. GNU separately compiles and runs
the entire adapted file. No FortFront whole-program success is claimed.

## Oracles and verification

See `tests/dynamic_character_constructor`: 72 source cases pass, comprising 60
successes, 10 controlled runtime errors and 2 source rejections. GNU executes 51
with exact expected output; 20 are compile-only references, and one has a pinned
GNU compiler limitation. All 48 adversarial harness checks and 74-file generator
replay pass. Two directly linked native programs pass 111 assertions (36 runtime/
public IR and 75 independent source adapter), with complete FPM debug flags.

GNU 14.2 has context-sensitive empty CHARACTER constructor length defects,
including zero lengths despite known nonzero operand descriptors and rejection
of a nested empty CHARACTER LEN. Those source bodies, first failures and
independent expected lengths are retained, not altered to match the compiler.
Their expected lengths follow J3/18-007r1 section 7.8 paragraphs 2, 5, 8, printed p89
(PDF p104): https://j3-fortran.org/doc/year/18/18-007r1.pdf . The no-type-spec
constructor takes agreeing type parameters from its ac-values; a zero-value
sequence does not erase its known type parameter. Descriptor inquiry is distinct
from prohibited loop-index/nonconstant-value-dependent zero-trip lengths.

All four directly affected historical suites pass unchanged (240 cases), and the
31-case release046 composition suite passes after promoting its unchanged
allocated-CHARACTER constructor fixture in both manifest and generator. Its
formatted output is compared byte-exactly, not whitespace-normalized. The
working-source harness proves the one-byte adaptation and reports its GNU full
run separately. Focused validation is not a complete release certification;
central integration performs the full clean aggregate.

## Runtime-fixed and assumed unallocated inquiry regression

The separate `tests/fixed_character_length_inquiry` followup retains the two
previously successful scalar-allocatable fixtures byte-for-byte and adds runtime
local/assumed dummy, scalar/rank-one, constructor and zero-trip inquiry checks.
All 20 cases pass: ten GNU executions, four independent zero-trip length oracles
with documented GNU limitations, and six controlled deferred-unallocated errors
with compile-only GNU references. The original 72-case constructor suite and
67-case scalar-allocatable suite pass unchanged. Six additional related inquiry/
procedure suites pass, for 356 targeted source cases, plus these 20 new cases.
Thirty harness checks, nineteen-file generator replay and the existing 36-assertion
source-free native guard program pass. No old source fixture or cap changed.

## Fixed results with derived actuals

The length preflight also validates scalar derived actual arguments of fixed
CHARACTER-returning functions, including type-bound passed objects, without
reading values or invoking the function for its declared length. Derived type,
component/default, scalar shape, procedure/result/actual and binding identities
remain checked; derived KIND operands are still invalid. The separate
`tests/fixed_character_derived_actuals` regression suite retains the historical
cross-feature source unchanged, covers nested/empty and non-evaluation paths,
and pairs exact GNU output checks with 30 malformed public-IR mutations.

The separate scope followup keeps component validation permission local to
fixed-CHARACTER function actuals and preserves independent strict intrinsic
operand policies. Context-sensitive memoization prevents shared-expression DAGs
from bypassing those policies. Bound receiver expression/declaration and first
formal type identities must match the binding's type. Seven source regressions
and 42 native assertions cover these boundaries without promoting historical
EOSHIFT/component negatives.

At the integrated 0.49 checkpoint, timing, runtime stdout-unit selection and
generic REPEAT fallback advanced the same byte-preserved working source to
2376:11, array-element internal WRITE in `integer_labels`. In 0.50 the bounded
element-file and numeric rank-three gather additions advanced that source to
2493:24, rank-one CHARACTER vector gathering, then excluded. Those are historical
checkpoint observations, not full utility execution. See the
[historical 0.50 scope](RELEASE-0.50.md). The bounded 0.52
[CHARACTER gather](CHARACTER-GATHER.md) and
[bare read-only actual](BARE_CHARACTER_GATHER_ACTUAL.md) additions advanced the
same preserved working source to the historical numeric rank-one gather boundary
at2678:36. The untouched original retains its 9329:55 storage-cap rejection.

## numeric-gather progression

Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed. See [numeric gathering](NUMERIC-VECTOR-GATHER.md) for the separate actual-association contract.

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../tests/utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
