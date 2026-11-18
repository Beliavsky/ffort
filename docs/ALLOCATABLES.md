# Bounded intrinsic allocatable arrays

The allocatable core supports INTEGER and REAL kinds 4 and 8 and default LOGICAL, rank one, two or three,
in main programs, procedure locals, and module data. Declare deferred dimensions
as `a(:)`, `a(:,:)` or `a(:,:,:)`, including a DIMENSION attribute. ALLOCATE requires explicit
bounds, with optional lower bounds, for exactly one whole array. DEALLOCATE also
takes one whole array. Both accept optional STAT naming a writable scalar INTEGER
variable local to the current scope. ALLOCATED accepts a whole allocatable array,
positionally or as ARRAY=. Parenthesized expressions, sections and nonallocatable
arguments are rejected.

Objects start unallocated. Successful allocation creates undefined elements;
SIZE, LBOUND, UBOUND, ALLOCATED and KIND can inspect the appropriate descriptors,
but reading an undefined element fails. KIND and ALLOCATED do not require
allocation; SIZE/LBOUND/UBOUND and data uses do. Zero-sized arrays are allocated
objects, with standard zero-extent inquiry bounds. DEALLOCATE destroys storage
and status; repeated deallocation or allocation without deallocation fails, or
sets nonzero STAT while leaving the object unchanged. STAT=0 means success;
particular nonzero numeric codes are not a portability contract.

Procedure-local arrays are fresh at each call and are automatically released
on return. Module allocations, bounds and defined flags remain shared across
nested calls and reset for each independent interpreter execution. Allocated
arrays can be passed to existing nonallocatable assumed-shape dummies, with the
existing association, overlap, INTENT and purity rules. Module allocation and
deallocation count as external effects for PURE/SIMPLE enforcement.

Array bounds remain within the supported default INTEGER range even when an
INTEGER(kind=8) expression supplies them. Extent multiplication is checked before
host allocation. The configured 1000000-element live-storage limit applies per call
frame and across module state. Deallocation releases that capacity. Allocation
failure or capacity exhaustion is recoverable through STAT; invalid expressions,
uninitialized bounds, out-of-range bounds, malformed IR and exhausted execution
budgets remain interpreter diagnostics. There is no silent allocation clamping.

The subset does not add pointer allocation, numeric scalar allocatables,
derived allocatables, rank four or higher, SAVE, multiple-object statements,
allocation type-specs, SOURCE/MOLD/ERRMSG or MOVE_ALLOC. Allocatable dummy
arguments support explicit INTENT(IN), INTENT(OUT) and INTENT(INOUT) within this
numeric/LOGICAL rank-one/two/three subset. Each actual must be a whole unparenthesized
allocatable variable with the exact declared type, kind and rank. IN accepts
unallocated arrays for ALLOCATED inquiries. OUT enters unallocated, even when
the actual was previously allocated. INOUT preserves allocation state, bounds,
values and definition flags. On return, OUT/INOUT replace the caller's complete
descriptor, including deallocation and bounds. Nested forwarding is supported.
Explicit-shape/assumed-size dummy declarations remain outside this subset.
OPTIONAL arrays are covered in [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md).
A whole unallocated object is absent when associated with a nonallocatable
OPTIONAL dummy; association with a required nonallocatable dummy is rejected.

Descriptor alias checks reject any same-object pair if an allocatable association
and either dummy is writable, including zero-sized/unallocated objects and
sections of the same object. Existing module host/USE alias restrictions continue
to apply. Before committing returned descriptors, the runtime checks the combined
new allocation sizes against the caller's live-storage pool. This prevents a
callee with a smaller local pool from overfilling its caller. Calls use the
existing value-result policy: descriptor/value copyout occurs on successful
return, with no caller mutation from failed argument evaluation or alias checks.

See [ALLOCATABLE-ASSIGNMENT.md](ALLOCATABLE-ASSIGNMENT.md) for automatic whole-array
allocation/reallocation and allocatable function results. The unchanged original
`alloc_sub_vec_int` and `alloc_sub_vec_real` utility bodies are tested with first
allocation, replacement through OUT and empty allocations; full utilities still
pass the earlier CHARACTER/OPTIONAL declaration gates and now stop at the unchanged array resource cap at 9329:55.

## Verification

The combined focused suites are `tests/allocatables`, `tests/allocatable_assignment`
and `tests/allocatable_dummies`. `test_allocatable_dummies` additionally mutates
actual descriptor attributes, intent, rank and expression forms.

`tests/allocatables/run_tests.py` runs independently specified source fixtures
through `--check` and execution. Safe cases also compile and run with GNU Fortran
using `-std=f2018 -pedantic-errors -fcheck=all -O0`. Unsafe/uninitialized reads and
interpreter-specific limits are separately classified and are not presented as
GNU conformance proofs. `test/test_allocatables.f90` checks repeated independent
runs and adapter/runtime rejection of malformed allocation metadata. The existing
native suite must continue to pass.

Default CHARACTER rank-one/two/three allocation is covered in [ALLOCATABLE-CHARACTER.md](ALLOCATABLE-CHARACTER.md).

Rank-three descriptor handling and focused evidence are detailed in [RANK-THREE-ALLOCATABLES.md](RANK-THREE-ALLOCATABLES.md).

LOGICAL array behavior and original utility evidence are described in [LOGICAL-ALLOCATABLES.md](LOGICAL-ALLOCATABLES.md).

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).

Scalar CHARACTER allocation is covered separately in [SCALAR-ALLOCATABLE-CHARACTER.md](SCALAR-ALLOCATABLE-CHARACTER.md).
