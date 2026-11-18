# Initialized main-program SAVE attributes

The SAVE attribute is accepted on explicitly initialized main-program intrinsic
scalars and fixed-shape arrays of ranks one through three. Supported types are
INTEGER(4/8), REAL(4/8), default LOGICAL and default CHARACTER with a supported
constant length. Every entity in the declaration must have a constant initializer.
Scalar expansion, conformable array initializers, non-unit lower bounds, zero
extents, DIMENSION attributes and multiple declarators retain their existing rules.

This is a source-contract extension, not a new persistent-storage implementation.
Fortran 2018 draft 18-007r1 section 8.5.16 paragraph 4 says main-program variables
already have SAVE implicitly; an explicit attribute confirms that duration.
Reference: https://j3-fortran.org/doc/year/18/18-007r1.pdf

## Storage duration and independent validation

The existing main activation owns each object for the complete execution. The
ordinary declaration-initializer instruction runs once before executable code.
Mutation survives subsequent calls, recursive calls and normal INTENT(INOUT)
copyback. Legal PURE dummy mutation remains legal. Main objects are not marked
with the procedure-local `is_saved` representation and do not use its module-like
shared store. No new mutable host association is introduced.

The parser retains all initializer constant/type/shape checks. The independent
FortFront adapter validates the source SAVE attribute, eligible main declaration,
root-owned representation, initializer-expression identity and initializer
assignment. Existing direct-runtime guards still reject a forged procedure-SAVE
flag or owner. This extension adds no direct-IR opcode or storage contract.

An independent native test runs the same immutable IR repeatedly, including after
a budget-failed root. Main arrays, CHARACTER data and scalar values start fresh
on each execution, as does the existing procedure-local SAVE counter used by the
test. The IR initializer is never mutated. This is per-execution storage, not
process-global interpreter state.

## Unchanged limits

The configured 1,000,000-element array cap and CHARACTER length/storage budgets are
unchanged. Main initializers remain constant expressions. Procedure-local array
SAVE is still unsupported, including its implicit form through initialization.
The existing initialized scalar procedure SAVE implementation is unchanged.

Standalone SAVE statements, uninitialized explicit SAVE, explicit module SAVE,
POINTER/TARGET/ALLOCATABLE SAVE declarations, derived/class objects and unsupported
kinds/ranks remain outside this bounded increment. Several of these are legal
Fortran but unsupported here; the source suite labels them as compile-only
boundaries, separately from invalid Fortran. No DATA, COMMON or new persistence
API is added. Existing rank-three reduction limits are unchanged.

## Original examples and tests

`tests/main_save/demo_minloc.f90` is the complete unchanged M_intrinsics example
from commit `fc14233036d910e3678d350efc24609e11475067`. It now checks and executes,
matching GNU output on all five rows:

```
1 3
1 3 1 3 2
3 5 4
5 4 3
7
```

The complete unchanged companion `demo_maxloc.f90` is preserved as a boundary,
not an execution success. It advances past SAVE and rejects its constructor
implied-DO at line 4, column 48: `Expected ), found ,`. Neither original source
was simplified or rewritten. Source and MIT-license hashes are in `upstream.json`.

The 62-case focused suite includes 40 GNU execution agreements, 14 compile-only
subset boundaries and eight GNU compile rejections. The native program adds
38 source/IR/ownership/reset/budget checks, and the runner has 14 self-tests,
including exact INTEGER(8) output above 2**53. GNU is only an independent oracle,
never the interpreter execution backend. Each compilation uses a fresh temporary
directory and `-std=f2018 -pedantic-errors -fcheck=all -O0`.

The unchanged historical `tests/saved_locals/cases/main_explicit_save.f90` is
promoted from a source rejection to GNU execution with output `0`. Only its
manifest expectation changes; no prior Fortran fixture is edited. That older
suite now has 17 executions, 11 compile-only boundaries and nine GNU rejections.
