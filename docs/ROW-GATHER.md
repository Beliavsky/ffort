# Bounded numeric array vector gathering

The read-only expression `matrix(rows,:)` accepts a named, non-POINTER rank-two
INTEGER(4/8) or REAL(4/8) array and a rank-one INTEGER(4/8) index expression.
The second selector must be the bare full-column `:`. The result has rank two,
shape `[size(rows),size(matrix,2)]`, and one-based value-expression dimensions.
Actual matrix row bounds are honored; index order and duplicates are preserved.
Scalar and triplet sections retain their existing semantics.

The index vector may be an array variable, constructor, section, supported
array-valued intrinsic, user array result or ELEMENTAL result. Each index element
is evaluated once per gather, not once per selected column. The runtime checks
all indices before reading matrix values, including when the matrix has zero
columns. It checks initialization of selected elements only. Empty index vectors
produce a zero-row result. All result/cache and index-temporary allocations obey
the configured 1,000,000-element limit; see ARRAY-LIMITS.md for configuration.

## Rank-three extension in 0.50

Numeric rank-three arrays additionally support `a(indices,:,:)`, `a(:,indices,:)`
and `a(:,:,indices)`. Exactly one axis uses a rank-one INTEGER(4/8) vector; the
other two selectors must be bare colons. The result retains rank three with the
selected extent replaced by vector size. The same value-snapshot, bounds,
definedness, alias and resource rules apply. Empty/KIND/public-IR validation
independently checks the full rank/axis/selector descriptor, including nested
cached-empty enclosing expressions, without evaluating skipped data.

`tests/rank_three_vectors` preserves exact select_tensor_real,
set_optional_integer and set_alloc_real_tensor routine bodies, with four
supported synthetic callers. Vendor0110 also preserves semicolon-separated
CASE bodies used by the original routine. A valid GNU continued CASE-header
location-mapping boundary remains explicitly tested. Rank-three RESHAPE, SUM
and ANY are not added by this feature; scalar-loop test oracles avoid those
unrelated bounded intrinsic paths.

The old `tests/row_gather/reject_rank3_base.f90` source is unchanged. It now passes
checking, then rejects its undefined gathered base data at runtime. It is not
promoted to an execution success; GNU only compiles this undefined-data fixture.
No row_gather generator is shipped, and the source hash remains unchanged.

## Value and alias semantics

A gather is an independently validated value expression, never a writable
designator. Its selected values are snapshotted in column-major order before
assignment or procedure argument association. This preserves self-assignment,
allocatable reallocation, duplicate selection and the original utility pattern
`call set_alloc((xx(true_pos(xmask),:)),xx)`: the input value is frozen before
an allocatable INTENT(OUT) actual is deallocated.

A rank-two or rank-three numeric gather supplied directly to a user procedure must be parenthesized and
associated with an INTENT(IN) dummy. Ordinary supported compound array value
expressions continue to use the existing argument-temporary rules. The parser,
independent frontend adapter and runtime all enforce the direct-gather rule.

The distinct [rank-one CHARACTER gather](CHARACTER-GATHER.md) additionally admits
[narrow bare read-only actuals](BARE_CHARACTER_GATHER_ACTUAL.md). That exception
does not relax the rank-two/rank-three numeric gathered-actual rule above. The
separate rank-one numeric extension below has a similarly bounded bare policy.

## Deliberate boundaries

This numeric subset is not general vector-subscript support. Rank-two vector columns remain
excluded; rank-three vectors may select any one axis. Multiple vector selectors,
LOGICAL/POINTER bases, CHARACTER bases outside their separate rank-one contract,
scalar/partial/strided selectors
on the other axes, vector triplet operands, scatter assignment, writable
actuals and unparenthesized direct user actuals outside the narrow rank-one
ordinary assumed-shape INTENT(IN) policy are rejected. Direct gathers in
WHERE/FORALL are rejected, preserving their per-element masked execution rules.
Gather expressions are outside the supported constant-initializer subset.

KIND remains an unevaluated inquiry: it can inspect the type without reading
undefined index or matrix values or requiring an allocatable base to be allocated.
SIZE/SHAPE currently prepare the gathered value. Thus a SIZE/SHAPE inquiry about
an otherwise valid gather can reject undefined selected matrix data, although GNU
Fortran can determine its shape without that read. This retained bounded
limitation is explicitly tested, not claimed as GNU execution agreement.

## Original utility evidence

`tests/row_gather/provenance.json` identifies byte-exact CRLF bodies from the
supplied `xutilities.f90` (SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`):

- `filter_matrix_rows`, lines8657–8679.
- `true_pos_func`, lines1552–1564.
- `set_alloc_real_matrix`, lines2610–2616.

Each standalone test uses the same synthetic module/DP parameter and narrow
generic interfaces around all three original bodies. No helper is replaced.
Nine synthetic drivers exercise selected/no/all rows, invalid columns, empty
rows/columns, repeated reallocation, no filters, and the original size-mismatch
STOP path (candidate status0 with its documented `STOP` stderr; GNU status0
without that stderr). The driver is new; the routine bodies and dependency closure are not
rewritten. GNU and the candidate execute the same fixtures. Full-module support
is not claimed: the unchanged full source still reaches its existing excessive
array declaration at9329:55 and the configured 1,000,000-element cap.

At the initial matrix-gather milestone, two older complete drivers in
`allocatable_spec_inquiries` and
`release034_integration` contain numeric typed empty array constructors. Those
unchanged drivers then reached later unsupported syntax. This is historical
verification context; current manifests record subsequent syntax support.
The predicate-only fragment passed at that milestone. The older `unsupported_vector_subscript` source is unchanged: its valid
row gather now passes checking, then rejects its undefined index at runtime.

## Independent producer and adapter checks

Vendor patch0059 preserves physical action locations in continued inline IF
statements, needed by the unmodified filter predicate. It also counts rank-one
INTEGER vector selectors in slice shape metadata, canonical frontend queries
and strict argument rank checking. No producer semantic checks are disabled.
The adapter separately checks source base identity, the vector expression,
exact type/kind/rank and all descriptor fields. Rank two requires a bare second
colon; rank three requires bare colons on both non-vector axes. Runtime direct
IR validation is independent of source matching. Native mutation tests exercise
both paths, forged scatter/actuals, physical locations and producer result rank.

Run `python3 tests/row_gather/test_runner.py` and
`python3 tests/row_gather/run_tests.py --candidate PATH --gfortran gfortran`.
The runner verifies fixture and original-body hashes, clean silent `--check`,
exact textual tokens, exact integers, finite numeric comparisons, and distinct
GNU compile/reject/run outcomes. Runtime safety/resource probes are not executed
under GNU unless separately marked safe. Interpreter native tests use the
repository debug profile; GNU oracles use `-fcheck=all` and FPE traps.

## Rank-one numeric extension

The separate [rank-one numeric contract](NUMERIC-VECTOR-GATHER.md) adds named non-POINTER INTEGER(4/8) and REAL(4/8) vectors. One INTEGER(4/8) index vector preserves bounds, duplicates and order; selected values are snapshotted before assignment or reallocation. Bare actuals are limited to ordinary matching rank-one assumed-shape INTENT(IN) dummies. They reserve the whole base against writable/host aliases, even for disjoint or empty selections; parentheses instead request an independent value snapshot. Bare ELEMENTAL scalar-dummy calls, writable gathers and scatter remain excluded. Numeric rank-two/rank-three actuals retain the parenthesized requirement above.
