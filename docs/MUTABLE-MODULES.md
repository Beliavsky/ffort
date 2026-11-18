# Mutable module data

Same-file modules may declare mutable INTEGER(4/8), REAL(4/8), LOGICAL and
fixed-length CHARACTER scalars and explicit-shape rank-one/rank-two arrays.
PUBLIC/PRIVATE, USE ONLY, earlier-module imports, contained procedures and
internal main-program procedures retain the same defining symbol identity.
Procedure-local declarations can shadow a host-associated module variable.

## Initialization and lifetime

A module has one storage instance for the complete execution, shared by all
calls, including defined formatted WRITE callbacks. Constant declaration initializers are validated before execution and
applied once. They may refer to earlier named constants, with the existing
assignment conversions, array conformance and CHARACTER padding/truncation.
Calling a procedure again never resets module values. Each independent
`execute_program` invocation starts a fresh module store, including after a
previous execution failed. The implementation uses no process-global mutable
module store.

A declaration without an initializer is undefined, not implicitly zero or
blank initialized. Scalar and per-element definition flags are shared along
with values. A module variable passed to an OUT dummy becomes undefined on
return if that dummy was not assigned. Empty arrays and non-unit lower bounds
retain the existing array semantics. Module arrays collectively have the
1,000,000-element storage cap, separate from each call frame's array cap.

## Effects and association

Ordinary subroutines and IMPURE ELEMENTAL procedures can update visible module
data directly, through a writable dummy, by internal WRITE or RANDOM_NUMBER,
or as a DO control variable. Active DO-variable guards are shared across calls.
PURE procedures may read module data but cannot modify it or pass it to a
writable dummy. SIMPLE procedures cannot reference mutable module variables,
including in specification inquiries; this keeps the existing narrower SIMPLE
contract. Ordinary functions may read module data but may not change it,
directly or through callees. This last restriction is the interpreter's safe
subset, not a claim that ordinary Fortran functions are pure.

Writable module actuals use the existing checked value-result association.
A module variable, element or section passed as a direct actual may not also
be referenced through host/USE association anywhere in that callee's transitive
call graph, including implicit defined-output callbacks. This conservatively rejects even read-only dual-path access and
disjoint sections of the same module array. A computed or parenthesized IN
actual is a value snapshot, so it does not create that binding. Ordinary local
actual alias rules are unchanged. Alias restrictions are checked before output,
and the runtime rechecks them for malformed IR.

## Boundaries and verification

POINTER, explicit module SAVE attributes, mutable derived-type module
objects, rank three, mutable main-program host association, nonintrinsic module USE renaming and
imported-name re-export remain outside this increment. Constant explicit shapes
and fixed CHARACTER lengths use the existing bounds/length contract.

The new differential suite is `tests/mutable_modules/run_tests.py`; the manifest
separates strict GNU execution, compile-only subset restrictions, invalid-source
rejections and interpreter-only safety cases. Native tests execute the same IR
twice to prove lifetime/reset behavior and mutate caches, purity and visibility
for independent adapter/runtime rejection. The adapter still checks exact AST
declaration identity, declared type/rank and every index for imported array
references whose pinned producer omits its array-access flag.

The untouched `xutilities.f90` passes `old_time_` (line 493) and explicit-shape
`mm(100,100)` (line 494). The 0.23 complete-file diagnostic was:

```text
xutilities.f90:495:10: Unsupported declaration attribute
```

That was the 0.23 boundary. Numeric allocatable module arrays now pass this
point, as do inferred-length CHARACTER parameters, the bounded PURE `choose(n,k)` specification call, and initialized local SAVE in recursive `gen`. See [ALLOCATABLES.md](ALLOCATABLES.md) and [SAVED-LOCALS.md](SAVED-LOCALS.md). The complete source remains unsupported; the isolated PURE/SAVE checkpoint reached the valid dummy name `procedure` in `assert_le` at 8187:40. The 0.33 contextual-name correction passed that declaration and reached the allocatable-dummy SIZE bound at 8663:63; current 0.34 progress is recorded below.

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).

Explicit intrinsic ISO_FORTRAN_ENV ONLY aliases are documented separately in
[ISO-FORTRAN-ENV-ALIASES.md](ISO-FORTRAN-ENV-ALIASES.md); ordinary module renaming remains unsupported.
