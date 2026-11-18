# SELECT CASE, CHARACTER scalars and array constants

The exact `examples/select_case.f90` program runs unchanged. The independent
source parser and pinned FortFront frontend must agree on its declarations,
bindings, expressions, CASE bounds and control flow before execution.

## Selection

`SELECT CASE` accepts a scalar INTEGER(kind=4/8), default LOGICAL or default-kind
CHARACTER expression. It evaluates the selector exactly once on each entry.
INTEGER and CHARACTER cases support discrete values, comma-separated alternatives,
inclusive ranges and one-sided ranges. LOGICAL cases support discrete values.
Bounds must be scalar constant expressions of the selector's type. Empty descending
ranges match nothing. Distinct branches cannot overlap, including CHARACTER
values equal after blank padding. At most one DEFAULT branch is permitted, and it
can appear anywhere in the construct. Nested SELECT, IF and DO constructs are
supported. Matching executes one case body; execution never falls into the next.
No matching case and no DEFAULT simply continues after END SELECT. A construct
is limited to 64 explicit values/ranges, in addition to its optional DEFAULT,
to bound compile-time overlap checking.

Named SELECT constructs, SELECT TYPE/RANK, EXIT targeting SELECT, INTEGER kinds other than 4/8, and non-default
LOGICAL or CHARACTER kinds remain outside this subset. Source limits,
block nesting limits and execution budgets continue to apply.

## CHARACTER scalars

Supported declarations are `CHARACTER`, `CHARACTER(n)` and `CHARACTER(LEN=n)`,
where n is a nonnegative integer literal or an earlier scalar INTEGER PARAMETER
name, up to 65,536 characters. The default
length is one. CHARACTER(LEN=*) dummies take the actual argument's length.
Assignment pads with blanks or truncates on the right. Zero-length scalars work.
CHARACTER scalar parameters, scalar function results, relational comparison and
TRIM (including STRING=) are supported. Comparison uses blank padding, so `"a"`
and `"a "` compare equal. Formatted A output preserves the stored length.

Fixed-length CHARACTER arrays, constructors and concatenation are supported from
0.18.0; see [CHARACTER-ARRAYS.md](CHARACTER-ARRAYS.md). Substrings, deferred/dynamic
length storage and general length arithmetic expressions remain unsupported. Fixed-length read-only dummies require an
actual at least as long and expose the declared prefix. Fixed-length writable
dummies currently require equal actual length to avoid partially defined values;
assumed-length writable dummies support OUT and INOUT. The runtime preserves
undefinedness independently of allocated character storage.

## Array PARAMETER

Rank-one and rank-two INTEGER(kind=4/8), REAL(kind=4/8) and LOGICAL PARAMETER declarations
support constant constructors, constant array expressions and scalar expansion.
Declared bounds are retained, including non-unit lower bounds and zero-sized
arrays. Named constant arrays are readable by indexing, sectioning, inquiries,
array intrinsics and procedure calls. Rank-one and rank-two constant sections
can initialize other constant arrays. Initializer ranks and each dimension must
conform. Unknown shape metadata is resolved by bounded constant shape evaluation
and independently rechecked by the adapter, including for empty sections.

The immutable cache is checked against a fresh constant evaluation by the adapter.
Assignments, writable argument association and RANDOM_NUMBER cannot modify a
PARAMETER. Array elements and sections are constant expressions only when their
base and subscripts are constant. User functions remain excluded from constant
initialization in this subset.

## Verification

`tests/select_case` contains 91 deterministic positive/negative differential cases,
the unchanged requested program, and a GNU Fortran oracle runner. The selector
single-evaluation case uses an IMPURE ELEMENTAL function with observable output.
`test_select_case_frontend` checks source/IR disagreement, and
`test_select_case_runtime` checks defensive runtime validation and immutable-array
cache errors. The focused suite supplements all prior release regressions.

A narrow pinned-frontend patch fixes nested SELECT bodies by parsing an inner
SELECT from the original token stream. See
`vendor/patches/0015-nested-select-bodies.md` for scope and replay details. This
does not transform user source or suppress frontend diagnostics.

Named/unnamed EXIT and CYCLE may target enclosing counted, bare or conditional
DO from a SELECT arm; see [CONTROL-FLOW.md](CONTROL-FLOW.md). Producer 0113 retains
complete SELECT CASE bodies inside DO WHILE using the parent token stream; this
does not add SELECT TYPE/RANK interpreter support.

## Same-line CASE bodies (0.50)

Vendor patch 0110 retains ordinary statements after a CASE header separator,
such as `case(1); call action()`, including CASE DEFAULT. It preserves normal
statement ownership and source-location checks, rather than bypassing the
adapter. A GNU-valid continued CASE-header fixture still reaches a pre-existing
physical-location mapping rejection; this is not a promise of general continued
CASE support. The original fixture, GNU execution and exact adapter boundary
remain in `tests/rank_three_vectors`.
