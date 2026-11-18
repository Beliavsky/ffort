# Bounded recursive procedures

Explicit `RECURSIVE` is supported on ordinary same-file module and main-internal
functions and subroutines, and bounded internal procedures within module procedures. It composes with PURE, SIMPLE and supported typed
function headers in either prefix order. Duplicate prefixes are rejected, and
RECURSIVE ELEMENTAL remains outside this subset. Direct and indirect cycles must
mark every participating procedure RECURSIVE, including cycles in unused code.
This explicit designation is a deliberately narrower boundary than modern
Fortran's implicit-recursion rules. A directly self-referencing function uses a
separate RESULT name, so its own name denotes the procedure rather than its
result variable.

## Activations and state

Each call owns independent arguments, unsaved local variables, function result, array
storage, optional-presence flags, loop state and expression caches. Automatic
arrays/CHARACTER lengths are evaluated for that call. Local allocatables and
allocatable function results are independently owned and finalized on return.
Supported mutable module data retains one shared store for the whole execution.
Initialized intrinsic scalar locals, with implicit or explicit SAVE, share per-procedure state across recursive activations. Their values and active DO-variable guards reset only for a new root execution. See [SAVED-LOCALS.md](SAVED-LOCALS.md).

The existing value-result argument association applies at every level. Actual
addresses and sections are frozen in the caller. OUT dummies invalidate incoming
definition state, and allocatable OUT dummies start unallocated. Definedness and
allocation descriptors return to the correct caller activation. Read-only aliases
and disjoint writable sections work; overlapping writable scalar/section actuals,
aliasing allocatable descriptors, and conflicting transitive module/SAVE associations
are rejected under the existing conservative rules. Recursion does not permit
mutable main-program host association or new pointer facilities.

Internal procedures bind to the defining host activation rather than copying its
locals. Recursive host re-entry creates a fresh host frame; a suspended internal
call resumes with its original host bindings. Siblings share the same host
activation. See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md).

All calls share the original execution budget. At most 64 procedure activations
may be active (not counting the main program); the 65th is a checked runtime error.
The guard runs before evaluating that invocation's actuals and is also enforced at
the frame entry API. Check-only mode cannot prove termination and accepts a
properly designated nonterminating cycle; execution fails at the depth/work limit.
A failed nested call does not copy its dummy values back to its caller. Earlier
completed external effects are not rolled back.

## Independent validation

The source parser retains RECURSIVE metadata, and the adapter independently
cross-checks both FortFront's prefix list and its recursive flag. Both source and
adapter graph analyses traverse cycles safely. Ordinary functions remain forbidden
from performing external effects through any reachable cycle member; PURE/SIMPLE
callee restrictions remain unchanged. The runtime independently refuses reentry
into a procedure that lacks the designation.

`tests/recursion` covers direct/mutual recursion, repeated calls, independent local
and loop state, automatic arrays, CHARACTER and allocatable results, optional
forwarding, generic dispatch, shared modules, aliases, undefined values, budget
exhaustion and the exact depth boundary. GNU Fortran is an independent oracle, not
the execution backend. Safety-policy failures and invalid/unsupported source are
not executed under GNU; the over-depth positive-language case is compile-only.

The original `pure recursive set_alloc_int_vec` body is retained verbatim from the
pinned xutilities source, including comments. Its harness covers no filter, either
optional bound, both bounds, empty inputs/results and reversed sections. The suite
verifies original source SHA-256 and exact body identity before running.

SIMPLE tests in the older PURE/SIMPLE suite retain their explicitly labeled PURE
reference lowering because GNU Fortran does not implement SIMPLE. Historical
fixture names ending `_recursive_unsupported` are retained for source identity,
but now expect successful evaluation. The historical `recursive_cycle` fixture
still rejects its procedure name `cycle`, a reserved-name boundary unrelated to
recursion; the `indirect_cycle` fixture now passes checking and fails safely at the
runtime call-depth limit.
