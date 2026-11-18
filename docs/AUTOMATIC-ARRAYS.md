# Bounded automatic arrays

Procedure-local explicit-shape arrays may have rank one or two and bounds that
depend on associated dummy arguments. Supported element types are the existing
INTEGER kinds 4/8, REAL kinds 4/8, LOGICAL, and fixed-length CHARACTER types.
Array-valued function result support is described separately; the allocation
mechanism also applies to such results when they are otherwise supported.

```fortran
subroutine scratch(n, data)
  integer, intent(inout) :: n
  real, intent(in) :: data(:,:)
  real :: work(-1:n-2, size(data,2))
  integer :: positions(size(data))
  work = 0.0
  positions = 0
  n = n + 1 ! does not resize WORK or POSITIONS
end subroutine
```

## Specification-expression subset

Bounds must have scalar INTEGER type. Existing constant bounds remain supported.
Nonconstant bounds support:

- Scalar INTEGER dummy arguments with explicit INTENT(IN) or INTENT(INOUT).
- Scalar INTEGER named parameters and integer literals.
- Integer unary signs and `+`, `-`, `*`, `/`, `**` arithmetic.
- Integer ABS, MIN, MAX, MOD and MODULO.
- SIZE of a whole assumed-shape or supported explicit-shape array dummy, or a
  named array parameter, optionally
  with a supported scalar INTEGER DIM expression.
- LBOUND/UBOUND of the same whole arrays with an explicit DIM.
- Scalar COUNT reductions of rank-one/rank-two LOGICAL masks. Masks can be
  whole input dummies or numeric/logical expressions over such dummies and
  constants. Arithmetic, comparisons, logical operations, and ABS, MIN, MAX,
  MOD, MODULO, INT, REAL, DBLE and MERGE are supported inside these masks.
  COUNT supports its existing keyword arguments, constant KIND=4/8 selectors,
  and DIM when reducing a rank-one mask to a scalar. Mask expressions may also
  use the supported descriptor inquiries and nested scalar COUNT calls.

All referenced dummies must have been declared before the local array.
Array inquiries inspect descriptors and do not read element values, so SIZE of
an undefined INTENT(OUT) array is allowed. Optional dummies, INTENT(OUT) scalar
values, local variable values, array element/section references, array
constructors remain unsupported as nonconstant bound values. Direct PURE module
functions with mandatory scalar INTEGER(4/8) inputs/results are now admitted as
[bounded specification functions](SPECIFICATION-FUNCTIONS.md). Other user-defined
specification functions remain unsupported. Whole-array dummies may still be associated
with caller sections and expression actuals. Other reductions are not added.
Mandatory ALLOCATABLE IN/INOUT dummies now support descriptor-only SIZE/LBOUND/UBOUND
inquiries; see [ALLOCATABLE-SPEC-INQUIRIES.md](ALLOCATABLE-SPEC-INQUIRIES.md). Inquiries
of ordinary local arrays and procedure pointer dependencies remain excluded.
Automatic arrays with declaration initializers or SAVE remain outside this feature.
Rank-three arrays follow [RANK-THREE.md](RANK-THREE.md). Bounded explicit-shape
dummies and their use in local descriptor inquiries follow
[EXPLICIT-DUMMY-BOUNDS.md](EXPLICIT-DUMMY-BOUNDS.md).
Bounded dynamic CHARACTER lengths are covered in
[CHARACTER-PROCEDURES.md](CHARACTER-PROCEDURES.md). Constant expressions in the other dimension retain their
existing supported forms, for example `integer :: a(n,int(2.9))`.

## Execution and safety

The runtime associates every scalar dummy and copies array dummy values,
shapes and definition flags before evaluating local bounds. It evaluates bounds
once at procedure entry, then allocates fresh local/result storage. COUNT reads
mask data and reports undefined elements; SIZE/LBOUND/UBOUND remain
value-independent. Dummy copies and locals are charged to the same frame cap. Later changes to an INTENT(INOUT) bound dummy do not change the local
shape. Separate invocations have independent storage and definition flags.
Normal return, early RETURN, and errors release the frame's allocatable storage.

Each bound must fit the supported default INTEGER index range, including a bound
calculated with INTEGER(kind=8). Bound arithmetic uses the existing checked
integer evaluator and consumes the shared execution-step budget. Zero and
negative extents produce empty arrays, with normal Fortran empty-dimension
SIZE/LBOUND/UBOUND semantics. Every dimension extent must fit the default INTEGER
range even when another dimension is empty. Extent products are computed only
after those checks.

The shared `max_array_elements` limit in `src/fi_ir.f90` applies to the total
storage of all arrays in the active frame, including actual-associated dummies
and fixed/automatic locals. The default is 1000000 elements. Dynamic violations
fail at call entry before the procedure body executes. This is a per-frame cap,
not a process-wide heap or byte cap. Existing temporary/result limits and the
64-frame call-depth policy still apply, including explicitly designated recursion. Allocator failure is diagnosed.
No automatic array element is implicitly initialized.

## Validation

The source guard checks the restricted specification-expression grammar. The
FortFront adapter independently matches declaration bounds and identifier
bindings, checks constant caches, and propagates unknown shapes for automatic
variables. The runtime checks automatic metadata, expression types, the permitted
bound grammar, index ranges, extents and allocation limits before allocation.

`tests/automatic_arrays/run_tests.py` checks frozen bounds, repeated/nested calls,
rank-one/two shapes, lower bounds, zero extents, numeric kinds, CHARACTER locals,
PURE procedures, inquiries of undefined OUT arrays, exact limits, overflow and
unsupported syntax. Compiler comparisons use GNU Fortran with
`-std=f2018 -pedantic-errors -fcheck=all -O0`. Resource-policy and undefined-read
cases are deliberately not claimed as compiler conformance tests.

`test/test_automatic_arrays.f90` also checks adapter/runtime rejection of malformed
IR, fresh definition flags and shared-budget exhaustion.

The utility-derived fixture preserves `true_pos_count` unchanged except newline
normalization and calls it with a local `jpos(size(tf))` scratch array. Its caller
is explicitly adapted to avoid unsupported allocatable output. Provenance is in
`tests/automatic_arrays/utility-provenance.json`; this fixture does not establish
support for the full original utilities module.

## COUNT-dependent results

`integer :: ipos(count(tf))` and `integer :: jvec(count(ivec>0))` are supported
explicit-shape function result declarations when TF/IVEC are suitable input
dummies. The bound is frozen even when an INOUT mask later changes. Empty masks
and all-false masks produce empty results. COUNT mask evaluation uses the shared
step budget and checked arithmetic; shape mismatches and undefined reads fail
before the procedure body executes. Empty masks do not read scalar operands.

`tests/count_bounds/run_tests.py` independently checks original `true_pos_func`,
rank-one/two locals/results, input kinds, frozen INOUT masks, constant KIND
expressions, zero extents, dummy copying, exact/over frame limits, work-budget
exhaustion and rejected bounds against GNU Fortran where a compiler oracle is
applicable. `test/test_count_bounds.f90` checks malformed metadata through both
adapter and runtime. `tests/count_pack_integration` retains exact original
`positive_int_vec` and combines COUNT-dependent results with PACK; it requires
both features. None of these fixtures establishes full utilities-module support.
