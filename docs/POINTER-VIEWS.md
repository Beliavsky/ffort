# Bounded POINTER views

This extension adds real backed array aliases, not copies of selected values.
The exact `get_data` declaration/association pattern is now executable: a fixed
caller TARGET matrix can be passed to an assumed-shape TARGET dummy and one of its
columns returned through an OPTIONAL POINTER INTENT(OUT) dummy. Changing the view
in the caller changes the original matrix, and vice versa.

The complete original `get_data` body is **not** claimed executable. Its error
branch still contains independent external I/O and implied-DO requirements. The
focused fixture is a synthetic wrapper of its declaration/association pattern,
not a byte-preserved original-body test. The unchanged complete xutilities source
first reached **6504:34** on explicit-shape dummy bounds in the isolated POINTER checkpoint. The integrated 0.32 release also admits bounded explicit dummies and now stops at **7967:40**, the user-defined `choose(n,k)` automatic bound.

## Supported contract

- Deferred-shape rank-one INTEGER or REAL pointers, kinds 4 and 8, in the main
  program or non-ELEMENTAL subroutines. Dummy pointers require explicit INTENT;
  OPTIONAL is supported, and descriptor operations on absent actuals are checked
  runtime errors. No pointer-valued function results or module pointers.
- Whole-array association with fixed rank-one local/caller TARGET storage, and
  rank-one sections of fixed rank-one or rank-two TARGET arrays. Section mapping
  is frozen at association time, including negative strides and empty sections.
- Whole pointer-to-pointer association (including a defined disassociated RHS),
  reassociation, one-argument NULLIFY,
  `p => NULL()` without MOLD, and one-argument ASSOCIATED.
- Main-program pointee reads and writes use normal supported array operations,
  including sections, overlap-safe assignment, WHERE, FORALL and RANDOM_NUMBER.
- Procedure pointer use is deliberately **descriptor-only**: association,
  NULLIFY, ASSOCIATED/PRESENT, and whole-pointer actuals to POINTER dummies.
  Ordinary pointer value access in procedures is rejected even in unreachable
  code. This restriction keeps caller aliasing coherent without weakening the
  existing value-result alias rules for ordinary dummy arrays.
- An eligible whole fixed TARGET actual passed to an assumed-shape TARGET dummy
  borrows the same backing storage and definition flags. Nested forwarding retains
  that backing identity. TARGET INTENT(OUT) invalidates shared flags at entry;
  POINTER INTENT(OUT) invalidates only association status.

The configured 1000000 live-owned-array-element cap remains in force. Aliases do not
allocate duplicate target buffers or consume that cap a second time. Existing
step limits, bounds checks, and undefined-value checks remain active. A separate
pointer association state distinguishes undefined, disassociated and associated;
empty associated views are still associated.

## Lifetime and alias safety

A view stores strided non-owning references to the owner's values and definition
flags, plus owner symbol, frame depth and generation. Every frame exit, including
an error, marks the generation dead. The runtime checks this identity before
inspecting association status or dereferencing the underlying Fortran pointers.
It rejects an escaping view of a callee local at descriptor copyout, before a
later caller could use it. A caller's backing survives the callee and can safely
be returned through the dummy. Reusing a call depth does not revive an old frame.

Whole non-TARGET actuals, allocatable actuals, and section actuals retain ordinary
value-result association for TARGET dummies. Trying to export a pointer into such
a copied dummy fails explicitly because there is no shareable caller backing.
Overlapping ordinary writable arguments remain rejected using canonical backing
identity. Passing the same POINTER descriptor to multiple dummies when one is
writable is also rejected. Distinct pointer descriptors may alias the same data
because procedure pointee access is excluded.

## Deliberate boundaries

Scalar, rank-two/three, LOGICAL, CHARACTER and derived pointers; pointer allocation
and deallocation; declaration association initializers; pointer bounds remapping;
component pointers; module/automatic/allocatable association targets; rank-three
TARGET sections; pointer-section association RHS; NULL MOLD; and multiple-object
NULLIFY remain explicit errors. Two-argument ASSOCIATED is now supported for the
bounded identity forms documented in [ASSOCIATED-TARGET.md](ASSOCIATED-TARGET.md). Main pointer
actuals may not bind ordinary nonpointer dummies. These are bounded subset limits,
not statements that the corresponding Fortran is invalid.

## Verification

`tests/pointer_views/` contains 56 fixed independent cases: ordinary aliases and
numeric kinds, row/column and negative-stride sections, zero extents, frozen
section mapping, definition flags, repeated descriptor/frame reuse, caller escape
and nested forwarding, nullification, overlap-safe updates, caps, unsupported
forms and lifetime failures. Expected results are fixed in the fixtures/manifest,
not copied from the candidate. GNU Fortran compiles each supported oracle in a
fresh temporary directory and executes defined success cases. Undefined-value or
association-status safety cases explicitly skip GNU execution and are not counted
as semantic oracle results. Other legal but excluded cases are compilation-only.

The runner independently checks `--check` and execution status, output, diagnostics,
source hashes and unchanged candidate hash. Its 13 self-tests check fail-closed
result assessment. `tests/pointer_frontend/` adds 40 source rejection cases.
`test_pointer_frontend` checks source/adapter consistency, repeated execution,
12 metadata mutations and 26 procedure-use/scope mutations. Separate runtime-only
native tests bypass frontend approval to exercise view lifetimes and forged IR.
The complete repository verifier remains a separate regression check.

The direct-runtime metadata suite passes 177 rejection cases covering forged
declarations, instruction operands,
shape/type caches, NULL/ASSOCIATED payloads and expired/unshareable targets. Every
mutation starts from a freshly parsed and successfully executed honest baseline.

No vendor producer patch is required. Source POINTER association is independently
matched to the producer's distinct pointer-assignment AST rather than accepted as
ordinary assignment.

Milestone result: all 122 native test executables, 56 focused cases, 40 source
rejections, 13 runner self-tests pass. Surrounding array, argument, elemental and allocation
CLI regressions also pass; full release verification remains a separate check. The unchanged
legacy array POINTER declaration fixture is promoted to success in both its
manifest and generator; scalar pointers remain outside the contract. See
`tests/pointer_views/verification.json` for captured hashes and exact scope.

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).
