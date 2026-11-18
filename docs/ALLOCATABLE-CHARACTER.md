# Bounded allocatable CHARACTER arrays

Default CHARACTER rank-one/rank-two/rank-three allocatables now share the numeric allocation
and argument descriptor machinery. This is a bounded extension, not general
Fortran allocation.

## Accepted declarations and statements

- Main-program, procedure-local and module arrays with fixed lengths, including
  supported procedure-entry specification expressions such as `LEN(input)`.
- Fixed-length or assumed-length `CHARACTER(*)` allocatable IN/OUT/INOUT dummies.
  The actual must be a whole allocatable array with the same rank and compatible
  length. Fixed dummy lengths require equality; assumed lengths use the actual's
  declared descriptor even when the actual is unallocated or has zero elements.
- Deferred-length `CHARACTER(:), ALLOCATABLE` arrays and allocatable dummies.
  Actual and dummy must agree on whether the length is deferred. Deferred objects
  have no defined LEN while unallocated; that inquiry fails safely.
- `ALLOCATE(CHARACTER(LEN=expression) :: array(bounds), STAT=status)` for deferred
  CHARACTER only. LEN is optional in the type selector; bounds and length use
  supported scalar INTEGER expressions. Negative lengths become zero.
- Ordinary ALLOCATE for nondeferred lengths, DEALLOCATE, ALLOCATED and the existing
  shape inquiries. Allocation status is separate from whether elements are
  initialized. Empty allocations retain the element length.
- Whole-array intrinsic assignment allocates or reallocates shape as necessary.
  Deferred lengths follow the array RHS length; nondeferred elements pad or
  truncate. Reallocation obtains whole-array RHS lower bounds, or one-based
  bounds for expressions and sections. If neither shape nor length changes,
  existing bounds survive. Scalar expansion requires prior allocation and
  preserves the array's element length and bounds.
- INOUT descriptor changes and OUT entry deallocation/copyback, including nested
  forwarding, zero-sized arrays, and OUT procedures that leave the result
  unallocated. Fixed, runtime and deferred allocatable array function results
  own their returned descriptors and storage.

Complete RHS values are prepared before committing assignment. Failed ALLOCATE
with STAT leaves the old status, bounds, length and values unchanged. Existing
aliasing, purity, uninitialized-value, element and execution-budget checks remain.

## Limits and exclusions

Each element is limited to 65,536 characters. New CHARACTER allocations and
reallocations additionally check a 16,777,216-byte live CHARACTER array payload
budget in their local-frame or shared-module storage pool. Argument entry and
copyout preflight that budget too. Descriptor and temporary overhead is separate;
this is not a process memory sandbox. Allocation-limit failures can be recovered
with STAT; assignment/copyout-limit failures stop execution.

Numeric scalar allocatables, rank four or higher, pointers,
nondefault CHARACTER kinds, substrings of array sections, SOURCE/MOLD/ERRMSG,
and typed ALLOCATE on nondeferred arrays remain excluded. Scalar CHARACTER is
covered by [SCALAR-ALLOCATABLE-CHARACTER.md](SCALAR-ALLOCATABLE-CHARACTER.md); bounded
multi-object lists are covered by [MULTI-OBJECT-ALLOCATION.md](MULTI-OBJECT-ALLOCATION.md). Untyped array
constructors require known equal item lengths; use supported explicit-length
CHARACTER constructors for deferred items. PACK and RESHAPE still require known
CHARACTER lengths. Deferred/runtime-length PACK is now rejected by the source
recognizer before program execution. Dynamic explicit-length dummies and general
user-function allocation length expressions are outside the length-expression
matcher.

Scalar substrings of allocated array elements use the separate
[rank-one/two/three element contract](ARRAY-ELEMENT-SUBSTRINGS.md); actual access
requires available storage and preserves the existing length/definition checks.

## Verification

`tests/allocatable_character/run_tests.py` checks 35 source cases against the CLI
and GNU Fortran with `-std=f2018 -pedantic-errors -fcheck=all -O0`. The manifest
labels each GNU execution, compile-only case, compiler rejection and interpreter-
only safety case. Two unchanged original utility bodies, `set_alloc_character_vec`
and `set_alloc_character_mat`, execute in a focused wrapper; their source-body
hashes are recorded in the manifest.

One compile-only test deliberately differs from GNU Fortran 14.2: assignment of
an empty explicitly typed CHARACTER constructor to a deferred allocatable should
retain the constructor's declared element length. The interpreter checks lengths
6 then 2; GNU reports zero for both. That case is not claimed as GNU runtime
agreement. Empty typed ALLOCATE is separately compared directly against GNU.

`test/test_allocatable_character.f90` tests the feature and 16 adapter/runtime
mutation rejections. OPTIONAL CHARACTER arrays are covered separately in
[OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md). The full utilities input still
requires features outside this bounded subset.
