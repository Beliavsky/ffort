# Two-argument ASSOCIATED

This extension adds a second, optional TARGET argument to the existing bounded
POINTER subset. `ASSOCIATED(POINTER[, TARGET])` returns a scalar default LOGICAL,
including for INTEGER(8) and REAL(8) pointers. Both argument keywords, including
reversed keyword order, are supported. The producer, adapter and runtime check
result metadata independently.

## Supported designators

- POINTER is a whole, unparenthesized rank-one INTEGER or REAL pointer of kind 4
  or 8. Existing main-program and non-elemental subroutine pointer restrictions
  continue to apply.
- TARGET is a whole compatible rank-one pointer; a whole rank-one fixed TARGET;
  or a rank-one section of a fixed rank-one/rank-two TARGET. Supported sections
  include negative and nonunit strides and a scalar subscript on one matrix axis.
- Local storage and shareable caller TARGET storage are supported. Assumed-shape
  TARGET dummies retain the caller's identity where existing argument association
  can share it. A copied dummy without shareable backing is rejected at runtime.
- Pointer sections as TARGET, scalar/rank-two pointer results, allocatable,
  module and automatic targets, rank-three bases, NULL MOLD, pointer allocation,
  pointer bounds remapping and procedure pointers remain unsupported. This does
  not assert that these constructs are invalid Fortran.

## Identity, state and lifetime

The two-argument result is true only for nonempty arrays of the same shape whose
corresponding elements occupy the same storage in array element order. Equal
values or a common backing allocation are insufficient. Reversed or shifted
views differ. Lower bounds do not affect identity; an otherwise equivalent
singleton view may use a different stride. A present empty TARGET produces false,
while one-argument ASSOCIATED remains true for an associated empty pointer.

A defined disassociated pointer produces false. Undefined association status and
expired target lifetimes are errors, including when the other argument would
otherwise make the result false. Owner generation and descriptor validity are
checked before any host pointer comparison. The comparison does not inspect
pointee values or initialized flags, so undefined target data is safe to inquire
about. Every compared element consumes a shared execution step. The existing
1,000,000-element array limit remains configured; no mapping-sized copy is allocated.

KIND validates structure without inspecting pointer association status or target
values. Empty surrounding expressions still validate call and designator metadata.
These inquiry rules do not make ASSOCIATED a constant expression.

## OPTIONAL omission and oracle limits

An absent whole nonpointer OPTIONAL TARGET is treated as an omitted second
argument, after checking the first pointer's status and lifetime. Absent first
POINTER, absent TARGET sections, and absent OPTIONAL POINTER TARGET remain
rejected by this bounded implementation. A present disassociated pointer target
is not an omitted target.

The exact primary references and scope are in
[optional-target-standard.json](../tests/associated_target/optional-target-standard.json).
The three supported omission cases use explicit specification expectations.
GNU 14.2 returns false for all three; only the disassociated-first-pointer case
agrees. They are compile-only in the main GNU oracle count, with observed GNU
execution recorded separately by `check_optional_target_omission.py`. Ordinary
supplied TARGET cases remain strict differential checks. Undefined association,
expired storage and interpreter-only subset/resource errors have no GNU runtime
agreement claim.

## Verification and provenance

`tests/associated_target` retains the complete unchanged M_intrinsics
`demo_associated.f90`, pinned by commit and SHA-256 with the upstream license.
It exercises the original one- and two-argument checks without source adaptation.
The suite also covers all four supported type/kind combinations, mapping/order,
empty and singleton views, keywords, caller aliases, optional forwarding, output
atomicity, lifetime and execution-budget failures, and a maximum-size identity.

Independent native tests mutate public IR before adapter, direct runtime and
metadata-only KIND evaluation. A separate producer test checks default LOGICAL
metadata, including REAL(8), keyword reordering and matrix sections. Vendor patch
0065 repairs only ASSOCIATED result metadata and adds no registry entry.

Historical POINTER tests retain their Fortran source bytes. The old two-argument
source rejection becomes an execution case with its exact normal STOP diagnostic;
an undefined two-pointer recognizer
probe now checks its runtime error. The old invalid-arity native mutation uses
three arguments because two are now supported.
