# Bounded internal procedures

Non-ELEMENTAL same-file module functions and subroutines may have a CONTAINS
section with one level of internal functions/subroutines. Internal procedures
can call their host, themselves when RECURSIVE, and siblings declared later.
Each recursive cycle retains the existing requirement that every participating
procedure explicitly has RECURSIVE. The 64-active-frame and shared-work limits
are unchanged.

Internal names belong to their defining host. They may shadow module procedure
names and may be reused by unrelated hosts. They are not module exports, cannot
be accessed from the main program or another host, and cannot be passed as
procedure arguments or stored as closures. The parser records the lexical parent;
the adapter independently verifies it against the producer AST and exact scoped
name binding. The runtime checks both lexical caller visibility and a live host
activation before entering an internal procedure.

## Host storage and activation

Supported captures are intrinsic INTEGER/REAL kinds 4/8, default LOGICAL and
fixed-length default CHARACTER scalars or ordinary rank-one/two/three arrays.
Host parameters and supported initialized SAVE values remain available. Local
or dummy declarations inside a child shadow host names. An internal procedure
can read or write supported host locals and dummies, subject to their INTENT,
definition state, active DO guards and procedure effect rules.

Each host call owns its ordinary local and dummy storage. Captures refer directly
to that exact live activation, including values, array descriptors, definition
flags and active DO-variable guards. Recursive calls of the host create a fresh
activation. When a suspended internal call resumes, it still uses its original
host; sibling calls use that same host. Internal locals and dummies are never
shared with another activation unless separately declared SAVE. Host or child
SAVE values retain the documented once-per-execution storage duration.

Live-frame references are cleared after normal return and every checked failure.
They cannot outlive the host or leak into another execute_program invocation.
The implementation uses no process-global closure or host-state store.

## Bounds, effects and aliases

Captured nonoptional scalar INTEGER host INTENT(IN/INOUT) dummies can appear in
the existing bounded automatic-array, explicit-dummy and CHARACTER-length
arithmetic expressions. Values are read from the already established host
activation before child local storage is allocated. Host local-variable values,
optional captures and unlisted host-dependent inquiries remain outside this
specification-expression extension. Internal functions are not admitted as PURE
specification functions; that feature remains limited to direct module functions.

PURE internal procedures may read supported host state but cannot change it.
SIMPLE procedures may use host parameters but not mutable host state. Ordinary
functions cannot mutate host data directly or transitively. Explicitly IMPURE
ELEMENTAL internal procedures retain the existing effect and ordered element
evaluation rules. A containing ELEMENTAL host remains unsupported.

The existing checked value-result dummy association is preserved. A direct host
actual cannot also be referenced through the callee's transitive host association,
even when both paths are read-only or different sections are used. This avoids
stale copy-back masking a host update. Parenthesized input expressions are
snapshots and remain allowed. A call into the defining host begins a new ordinary
activation, so its new locals are not confused with older captured storage.
Module and SAVE alias guards retain their distinct shared-storage behavior.

## Explicit exclusions

Capturing host OPTIONAL, POINTER, TARGET, ALLOCATABLE, derived/polymorphic,
runtime-length CHARACTER or function RESULT objects is rejected. Declaring an
unused such host object does not prohibit unrelated supported captures.
More deeply nested internal CONTAINS, ELEMENTAL hosts, mutable main-program
host association, procedure dummy arguments, procedure pointers and closures
remain unsupported. Main-program internal procedures otherwise retain their
previous behavior. No source, array, KIND or execution limit is increased.

## Original quick_sort and verification

The new suite embeds the complete original quick_sort routine from xutilities
lines 8870–8942, including quick_sort_1 and interchange_sort. The 2,517-byte body
and all 73 CRLF line endings are unchanged. The runner checks the original file
SHA-256 and exact body identity. A new harness supplies dp and a small elemental
isnan generic; its helper and driver are not claimed as original source.

GNU comparisons cover empty/singleton input, interchange-sort thresholds, larger
finite-valued inputs with duplicates, sorted/reverse order, permutation and
value/index consistency, and repeated calls. Independent native mutation tests
check lexical-parent metadata, unsupported captures, visibility, purity, repeated
roots, budget exhaustion and activation cleanup. GNU is only an oracle, never
an execution backend. Invalid or unsafe alias/depth tests use compile-only or
source-rejection baselines rather than unsafe reference execution.

The untouched full utilities source now reaches read_vec_data_unit at 9329:55:
its fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element
limit. The diagnostic is explicit and emits no stdout. This is the first
remaining declaration gate, not evidence that every preceding executable
routine is supported. External READ/file I/O remains outside the subset.
