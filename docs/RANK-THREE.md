# Bounded rank-three array support

This increment extends the existing interpreter array model to rank three. It does not enable unrestricted Fortran array ranks or every transformational intrinsic.

## Supported contract

- Explicit-shape intrinsic arrays with up to three dimensions, including nonunit lower bounds, zero extents, and integer, real, logical, and character elements.
- Third-axis element reads and writes; whole-array assignment; scalar expansion; conformable elemental expressions.
- Sections with scalar selectors or triplets in any axis. Result rank is the number of triplets. Sections may therefore have rank one, two, or three. Explicit negative strides, noncontiguous sections, and overlapping assignment retain snapshot semantics.
- `SIZE`, `LBOUND`, and `UBOUND` inquiries in dimensions one through three, within the existing scalar-DIM inquiry interface.
- Assumed-shape intrinsic dummy arguments, ordinary argument association and copy-back, optional array arguments, elemental procedures, and automatic local/result arrays whose bound expressions satisfy the existing bounded automatic-expression rules.
- Independent FortFront AST/IR cross-validation covers all three bounds and subscript expressions. Cached rank, extent, dimensions, declaration identities, and section metadata are not trusted without checks.

Fortran column-major order is preserved: the first subscript varies fastest. Equal element counts do not make different shapes conformable. Whole-array and section assignments must agree in their dimension extents unless using scalar expansion.

## Limits and exclusions

The array element cap remains 1000000. Individual constant bounds remain default-INTEGER bounded. Extent products use checked multiplication and cannot wrap when three large dimensions exceed the integer product range. A zero-volume shape remains zero volume even if another dimension is large, subject to the independent bound and extent limits.

Ranks four and above remain unsupported. Numeric, LOGICAL and CHARACTER allocatable arrays now support ranks one through three; see [RANK-THREE-ALLOCATABLES.md](RANK-THREE-ALLOCATABLES.md). Rank-three use of PACK, RESHAPE, MATMUL, reductions, and location reductions is not enabled by this increment. Existing rank-one and rank-two support for those operations remains in place. This is not a claim of unrestricted automatic specification expressions, derived-type array support, general vector subscripts, or arbitrary higher-rank transformational intrinsics. The bounded 0.50 numeric single-vector gather on any one rank-three axis is documented in [ROW-GATHER.md](ROW-GATHER.md); rank-two gathering remains row-only.

## Original utility provenance

`tests/rank_three/xutilities_tensor_original.f90` contains the original `tensor(xmat)` function supplied in xutilities, with only line endings normalized. Its automatic result is declared `xtens(size(xmat,1),size(xmat,2),1)` and its original executable statement is `xtens(:,:,1) = xmat`.

The differential fixture `tests/rank_three/cases/original_xutilities_tensor.f90` uses that exact procedure body inside a synthetic module and executable driver. The module wrapper, kind constant, and driver are test scaffolding, not original xutilities text. The manifest includes a SHA-256 of the normalized procedure body. Passing this fixture establishes support for that procedure, not for the entire xutilities module; later rank-three allocatable declarations are handled by the separate bounded allocation extension.

## Verification

`test/test_rank_three_frontend.f90` checks valid explicit, assumed-shape, and automatic-array baselines, then independently forges 31 metadata disagreements involving third-axis bounds, element indices, target indices, triplet operands, cycles, shape caches, and equal-sized but differently shaped arrays.

`tests/rank_three` contains an independently specified Python fixture generator, CLI harness, harness self-tests, and GNU Fortran differential cases. The harness tests both checking and execution, exact exit classifications, stdout leaks, and expected values. GNU compilation uses fresh temporary directories. Huge-bound and cap-policy cases explicitly skip GNU and are not counted as differential evidence. See the suite README for commands and its result JSON for the actual run status and executable hashes.

The focused verification run passed all 50 candidate cases and all 45 GNU-oracle cases; five safety-policy cases were deliberately excluded from GNU. All 12 harness self-tests passed. These counts describe the focused suite, not a claim that the entire repository suite was rerun.

Additional focused cases cover rank-three RANDOM_NUMBER whole arrays and reversed sections by range/shape invariants, PARAMETER scalar initialization with constant slicing and bounds, and exactly-once IMPURE ELEMENTAL third-index evaluation for reads, writes, and scalar dummy binding. GNU RNG values are never compared directly with the interpreter stream.

`test/test_rank_three_runtime.f90` passes 12 direct-runtime metadata mutations, including third-index bounds, malformed cached dimensions, and third-axis fields hidden in rank-two or nonsection expressions. Its captured PRINT stream verifies no partial record escapes on these errors. Seeded rank-three RANDOM_NUMBER execution independently verifies range, exactly eight draws, and identical output on a fresh run with the same explicit state.

## Rebuilding IR consumers

The public prototype IR now has three-wide shape descriptors and third-axis bounds/selectors. Rebuild the complete library and all callers after upgrading; do not reuse old module files or archives. Direct IR producers must initialize the full descriptor consistently. Independent runtime validation rejects malformed metadata rather than assuming older two-wide layouts.
