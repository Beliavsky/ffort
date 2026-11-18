# Numeric TRANSPOSE and scaled NORM2

This bounded interpreter implementation does not call an external compiler to execute source.

## Contract

- `TRANSPOSE(MATRIX)` accepts a rank-two INTEGER(4/8) or REAL(4/8) array, preserves its type and kind, reverses its two extents and maps result `(i,j)` to input `(j,i)`. LOGICAL, CHARACTER, COMPLEX and derived-type matrices are outside this subset.
- `NORM2(X [, DIM])` accepts REAL(4/8), rank one through three. The result retains the input type/kind. Without DIM it is scalar; with scalar INTEGER(4/8) DIM it removes that dimension. Dynamic DIM is checked against the input rank before any element access. `X=` and `DIM=` keywords can be reordered. `ARRAY=` is not a NORM2 keyword.
- The formal DIM cannot be a direct OPTIONAL dummy, consistent with the intrinsic restriction. A parenthesized present optional expression is evaluated normally.
- Sections, expressions, non-unit declared lower bounds, empty extents and existing alias-safe assignment/reallocation compose with these operations. Existing pointer restrictions remain: this baseline admits rank-one numeric pointers, so NORM2 can consume them but rank-two pointer declarations for TRANSPOSE remain unsupported. Temporary result bounds are the ordinary expression bounds, not the input's declared lower bounds.
- An empty norm has positive zero. Reducing a zero-length axis produces zeros for each remaining result element. If a remaining axis is empty, there are no result elements to evaluate. Ordinary evaluation still requires a valid allocated/associated input descriptor; KIND requires only valid declared metadata and does not read undefined data or evaluate DIM.
- KIND of either operation validates expression structure, including operand references and cycles, without reading its data. Public-IR and independent frontend checks validate type, kind, rank, shape caches, slots and unused selector metadata.

## Numerical and resource policy

NORM2 uses a scaled sum of squares. Ratios are formed before squaring, avoiding intermediate `x*x` overflow and avoiding needless underflow for small inputs. Operations use the input REAL kind; REAL(4) is not silently promoted to REAL(8). A one-element positive subnormal remains that exact value. All-zero inputs return positive zero.

Evaluated NORM2 inputs and the result must be finite. A result outside the represented REAL range is rejected before the overflowing multiplication. This finite-result policy is an interpreter restriction, not a claim that GNU rejects the same program. A KIND inquiry does not inspect nonfinite stored values.

TRANSPOSE maps individual elements without a second intrinsic-owned result buffer. NORM2 keeps constant-size numerical state per reduction and visits input elements in column-major order. Both use checked shape products, the configured array limit and the normal statement/element step budget. Existing assignment, procedure-result and output staging rules still apply. This does not remove their memory costs or other limits.

## Evidence and upstream preservation

The focused suite is `tests/matrix_norm`. Its two original M_intrinsics files are preserved byte-for-byte, with hashes, repository commit and license in `upstream.json` and `UPSTREAM_LICENSE`. The runner verifies provenance before executing tests and rejects successful stderr, check stdout and unintended empty-output whitespace.

The numerical oracles include exact small mappings, rank-three DIM slices, independent 3-4-5 norms, equal-component norms, positive subnormal checks and near-HUGE values. Small norms use positive-result and relative-error assertions, not an absolute tolerance that could accept zero.

GNU Fortran 14.2 on the supplied toolchain returns zero for six positive tiny/subnormal probes: 3-4-5 vectors at REAL(4) 1e-30 and REAL(8) 1e-300 scale, equal components at TINY/2, and one smallest positive subnormal, in both kinds. These observations are retained separately. Those six cases are GNU compile-only in the strict comparison and use independent mathematical/representation oracles for candidate execution. They are not reported as GNU execution agreements. Other compile-only cases cover undefined/unallocated data, finite overflow policy and the unsupported TRANSPOSE types.

Focused native tests separately validate producer resolution, source shadowing and malformed direct IR, including KIND and empty-result paths. Ordinary-function writes to SAVE/module state remain rejected; this feature does not expand procedure side effects. The aggregate verifier runs the focused runner and its adversarial self-tests.

## Primary references

- [J3/23-007r1, 16.9.153](https://j3-fortran.org/doc/year/23/23-007r1.pdf): NORM2 uses X, its dimension/result rules, zero-size result, and the recommendation to avoid undue overflow or underflow.
- [GNU TRANSPOSE](https://gcc.gnu.org/onlinedocs/gfortran/TRANSPOSE.html): rank-two shape and element correspondence. The interpreter deliberately supports only the numeric kinds above.
- [GNU NORM2](https://gcc.gnu.org/onlinedocs/gfortran/NORM2.html): general operation and result shape. Its documentation labels the first argument ARRAY; the standard and GNU compiler accept the keyword X instead.
