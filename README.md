# FortFront REPL bare-value fix (complete source)

Changes are applied. Extract into a fresh directory and use the existing build
workflow. No manual patching is required. This is a development preview.

The exact regression now works:

```fortran
integer, parameter :: n = 5
n
```

The query prints `5`. Bare mutable variables and array elements still print their
current values. `.vars` and `.info` also show scalar PARAMETER constants correctly.
Repeated queries do not replay earlier statements or random-number effects.
Scalar PARAMETER caches are checked against bounded immutable initializers before
pending effects. Parameter assignment, RANDOM_NUMBER output and DO-index writes
are rejected. Undefined mutable values still report an error.

This is not typed live-declaration growth. New PARAMETER, explicitly kinded and
array declarations must precede execution; existing growth restrictions remain.
See [scope and examples](docs/REPL-VALUES.md).

Validation on Linux: 338 existing REPL methods in normal and Python -O modes;
9 new author cases and 18 independent cases in both modes; 18 READ-section smoke
cases; and five focused native programs totaling 1,019 checks. One obsolete
PARAMETER rejection fixture was replaced with a repeated-query, prefix-once test.
No new full native-suite run, Windows execution or clean maintained-suite
certification is claimed. Prior READ-section support remains included unchanged.

---

Earlier preview READMEs below are historical, not this checkpoint.

# FortFront internal READ sections preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patching or prebuilt binary is required.
This is a development preview, not a certified release.

New interpreter support: internal list-directed READ into rank-one INTEGER,
REAL or default-CHARACTER sections, including variable bounds and strides,
fixed/allocated arrays and permitted OUT/INOUT dummies. Destination offsets are
validated and frozen before transfer. Null/slash preserves old values and flags;
conversion error/EOF invalidates selected data-list elements, not untouched
array elements. Existing IOSTAT and safety-error distinctions remain unchanged.
See docs/INTERNAL-READ-SECTIONS.md for scope, bounds and failure semantics.

The unchanged authorized working utility advances from 3084:47 to 3550:30,
where dual-vector matrix subscripting remains unsupported. Both check and run
stop in source validation with no output; full utility execution is NOT claimed.
Its prior single-digit nmax adaptation remains the only source-byte difference.
No REPL, vendor-parser or frontend changes are included in this batch.

Linux app build and full native FPM suite passed. Verification includes 338 REPL
methods and 18 new READ methods per normal/Python-O mode; 45 author and 146
independent native checks; 32 GNU differential, 18 failure/definedness and 4
procedure cases per mode; 218 affected existing READ source cases with GNU.
One existing fixture changes from unsupported-source to undefined-input runtime
failure; 13 exact diagnostic pins are explicitly migrated, with fixture bytes
and failure stages/locations/outputs preserved. Windows remains untested;
no clean maintained-suite certification is claimed.

See PREVIEW-STATUS.json and evidence/read-sections-preview/.

---

Earlier preview READMEs below are historical, not this checkpoint's scope.

# FortFront REPL array-intrinsics preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patching or prebuilt binary is required.
This is a development preview, not a certified release.

New: retained rank-one ABS, SQRT, SIN, COS, EXP, LOG and LOG10, plus SIZE,
LBOUND and UBOUND with optional DIM. Positional and standard keyword arguments
work in bare queries. Whole-array bounds, parenthesized/expression bounds,
empty arrays and undefined-value inquiries follow existing engine semantics.
Prior effects and RNG state never replay. Invalid admission preserves state;
actual domain, undefined-value and DIM runtime failures retain the taint rules.

Patch 0121 prevents speculative output implied-DO parsing from leaving orphan
keyword nodes for ordinary parenthesized expressions. Genuine implied-DO parsing
is unchanged, and the frontend's strict unmatched-keyword validation is intact.
Only the admitted rank-one subset is expanded; KIND arguments remain excluded.

Linux app build, full native FPM suite and 338 transcript methods in normal and
Python -O modes passed. Additional checks: 42 native author, 199 native mutation,
23 query-classifier, 46 compiled-gfortran oracle, 28 lifecycle, 14 producer CLI
and 25 native producer checks. The latter includes producer-only complex literals,
not new interpreter complex support. Windows remains untested; no clean
maintained-suite certification is claimed.
See docs/REPL.md, PREVIEW-STATUS.json and evidence/repl-array-intrinsics-preview/.

---

Earlier preview READMEs below are historical, not this checkpoint's scope.

# FortFront REPL SELECT CASE preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patching or prebuilt binary is required.
This is a development preview, not a certified release.

New: retained SELECT CASE with INTEGER, LOGICAL or CHARACTER selectors,
value lists/ranges/default, nested IF/SELECT/DO, and valid enclosing EXIT/CYCLE.
Selectors evaluate once; completed blocks retain values without replaying prior
output or RNG effects. Incomplete blocks stay buffered; runtime failures taint.
Case chains, ownership, constant bounds and continuation boundaries are checked
before any pending effects. Narrow vendor patch 0120 fixes nested END SELECT
boundary detection and case-insensitive keyword matching without rewriting text.

Bounds include 64 nested SELECT levels and 64 alternatives per SELECT. Constant
CASE expressions are bounded; CHARACTER subexpressions must be literals.
Use spaced END SELECT; compact ENDSELECT and named SELECT remain unsupported.

Linux app build, full native FPM suite and 312 transcript methods in both normal
and Python -O modes passed, plus 67 native author checks, 179 independent native
mutation checks, 29 compiled-gfortran oracle cases and 12 lifecycle checks.
Windows remains untested; no clean maintained-suite certification is claimed.
See docs/REPL.md, PREVIEW-STATUS.json and evidence/repl-select-preview/.

---

Earlier preview READMEs below are historical, not this checkpoint's scope.

# FortFront REPL inspection preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patching or prebuilt binary is required.
This is a development preview, not a certified release.

New since structured loops: `.vars [names]`, `.info [names]`, `.shapes [names]`
and `.sizes [names]`. Selected names are case-insensitive and retain order and
duplicates. Inspection executes admitted pending source once, never replays old
effects, and preserves existing taint/edit gates. Invalid or unknown filters are
rejected before pending execution. `.info` includes type/kind/rank, CHARACTER
length and bounded value display. Shape/size defaults list arrays only.

Only REPL command code changed, not the runtime engine. App compilation and the
complete 295-method REPL transcript suite passed on Linux in normal and Python
-O modes, plus independently authored adversarial inspection checks. The prior
structured-loop native suite remains historical evidence; no new full native
suite was run for this command-only change. Windows remains untested; no clean
maintained-suite certification is claimed.

See docs/REPL.md, PREVIEW-STATUS.json and evidence/repl-inspection-preview/.

---

Earlier preview READMEs below are historical, not this checkpoint's scope.

# FortFront REPL structured-loop preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patching or prebuilt binary is required.
This is a development preview, not a certified release.

New since the plain-scalar growth preview: retained DO WHILE, bare DO, named
loops and EXIT/CYCLE, including transfers to an enclosing named loop. Completed
loops preserve values and RNG state without replaying earlier output. Nested
loops and IF are supported up to 64 active loop levels. Incomplete blocks stay
buffered; runtime failure or step exhaustion taints the session rather than
retrying partial effects. SELECT CASE remains explicit-run-only.

Uppercase/mixed-case WHILE headers now work through a narrow parser correction;
string literals and source spelling are not rewritten.

Validation: full native FPM execution passed on Linux; 275 transcript methods
passed normally and under Python -O; 104 author, 86 independent CFG and 2937
independent loop-form native checks, 18 gfortran-oracle CLI cases and 24
additional keyword/literal-preservation cases passed.
Receipts: PREVIEW-STATUS.json and evidence/repl-loop-control-preview/.
This is not clean maintained-suite certification. Windows remains untested.

Existing bounded-array expression and one-fresh-plain-scalar growth limitations
are unchanged. See [REPL rules](docs/REPL.md) for scope and no-replay semantics.

---

Earlier preview READMEs below are historical; their narrower scope and validation
counts do not describe this checkpoint.

# FortFront REPL plain-scalar growth preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patching or prebuilt binary is required.
The executable retains the baseline development version; this is not a certified release.

New since the array-expression preview: after executing or querying, add one
fresh `integer :: name`, `real :: name` or `logical :: name` without losing old
values or replaying output/RNG effects. The new scalar begins undefined. The
source declaration is visibly hoisted before executable statements; .list/.save
show standard Fortran with the resulting line shift. Pending statements remain
pending until a later execution-triggering operation.

A dedicated transaction validates both full source versions and retained-prefix
identity, then commits staged ownership without executing instructions. Rejected
declarations preserve source and state. Ordinary execution keeps its strict
prefix checks. Four runtime allocation-failure points were explicitly tested.

Validation: full native FPM execution passed on Linux; 254 transcript methods
passed normally and under Python -O; 338 transaction, 73 source-helper, 368
independent native checks and 16 independent CLI boundary cases passed.
Receipts: PREVIEW-STATUS.json and evidence/repl-growth-preview/.
This is not clean maintained-suite certification. Windows remains untested.

Initial scope is one fresh default-kind INTEGER/REAL/LOGICAL name with mandatory
`::`, optionally followed by a comment. No attributes, kinds, initializers,
arrays, CHARACTER or multiple names. Existing declaration continuations and
semicolon-separated specifications are conservatively refused for growth.
The body must be complete and healthy; open blocks, taint, nonresumable runs and
executed-source editor gates cannot be bypassed. See [REPL rules](docs/REPL.md).

---

Earlier preview READMEs below are historical; their narrower scope and validation
counts do not describe this checkpoint.

# FortFront REPL array-expression preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patches or prebuilt binaries are needed.
The executable retains the baseline development version; this is not a certified release.

New since the counted-DO preview: homogeneous rank-one scalar-item constructors,
array copy/arithmetic/comparisons/logical operations with scalar expansion, and
one-argument SUM, PRODUCT, MINVAL, MAXVAL, ALL, ANY and COUNT. For example, after
`integer :: a(3)`, enter `a=[1,2,3]`, `a=2*a`, then `sum(a)` to obtain 12.
Array values, definedness and RNG state survive queries and appended statements
without replay. RHS staging preserves self-referential assignments.

This also fixes retained commit failures after legitimate numeric scalar
broadcast conversions, such as assigning integer 1 to a REAL array. Runtime
output is canonicalized; strict checks on external IR and restored state remain.

Validation: the full native FPM run passed on Linux, 234 transcript methods
passed normally and under Python -O, and 88 focused plus 403 independent native
array-expression checks passed. Prior retained-runtime native regressions passed.
Receipts: PREVIEW-STATUS.json and evidence/repl-expressions-preview/.
This is not clean maintained-suite certification; Windows execution is untested.

Constructors are nonempty, untyped and scalar-item-only, capped at 256 items.
Array operands/copies require matching types and kinds. Sections, array math
intrinsics, exponentiation, mixed kinds, reduction MASK/DIM/KIND, array RNG,
rank-two/dynamic arrays, and declaration growth remain outside retained mode.
Existing source-line and execution budgets still apply. See [REPL rules](docs/REPL.md).

---

Earlier preview READMEs below are historical; their narrower scope and validation
counts do not describe this checkpoint.

# FortFront REPL counted-DO preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No patches or prebuilt binaries are required.
The executable retains the baseline development version; this is not a certified release.

New since the IF/arrays preview: complete unnamed counted DO blocks execute once
on retained values. Nested loops and IF can populate fixed rank-one arrays;
queries, .vars and later loops preserve values without replaying earlier output
or RNG calls. Only a complete closed loop commits. Runtime errors, including
step exhaustion, taint the session rather than retrying partial effects.

A narrow vendor parser correction also makes DO/END DO/ENDDO keyword matching
case-insensitive. Source text, string literals and comments are not rewritten.

Validation: full native FPM test execution passed on Linux, plus 210 transcript
methods normally and under Python -O, 126 native loop checks, 172 independent
control-flow checks, 648 frontend case checks and 24 independent real CLI case
checks. Exact receipts are in PREVIEW-STATUS.json and evidence/repl-loops-preview/.
This is not clean maintained-suite certification. Windows execution remains untested.

DO WHILE, bare DO, EXIT/CYCLE and named loops remain outside retained sessions.
Array expression expansion, declaration growth, auto-END, autorun, let/const,
arbitrary source loading and runtime snapshots remain incomplete. Explicit .run
continues to offer the broader ordinary interpreter, without implicit replay.
See [REPL rules](docs/REPL.md).

---

Earlier preview READMEs below are historical; their narrower scope and validation
counts do not describe this checkpoint.

# FortFront REPL IF and rank-one array preview (complete source)

Changes are already applied. Extract into a fresh directory and use the existing
FPM/Windows build workflow. No manual patches or prebuilt binaries are included.
The executable retains the baseline development version; this is not a certified release.

New since the editor preview: complete nested IF/ELSE IF/ELSE and single-line IF,
plus retained fixed rank-one INTEGER/REAL/LOGICAL arrays. Scalar broadcast,
element reads/writes, whole-array PRINT/query and bounded `.vars` inspection are
supported. Queries and appended statements never replay earlier effects. Undefined
elements remain undefined; runtime errors taint the session until reset.

Validation: all native FPM test programs completed successfully on Linux, along
with 47 focused native array checks, 192 scalar/IF checks, 118 branch-admission
checks, 10 independent array transcript methods and 20 IF methods (both normal
and Python -O), and all 163 previous REPL transcript methods (normal and Python -O). Exact receipts
are in `evidence/repl-if-arrays-preview/` and `PREVIEW-STATUS.json`.
This is not full clean maintained-suite certification. Windows execution remains untested.

The array subset excludes CHARACTER/dynamic arrays, sections, constructors,
array arithmetic/copy and reductions. Retained loops and general procedures,
auto-END, autorun, let/const, arbitrary source loading and runtime snapshots are
not implemented. See [REPL rules](docs/REPL.md).

---

The earlier preview READMEs below are historical; their narrower scalar-only
scope and validation counts do not describe this new checkpoint.

# FortFront REPL source-editor preview (complete source)

This ZIP contains the applied changes. Extract into a fresh directory and use the existing build workflow; no manual patches are needed. The executable retains its baseline development version and this is not a certified release.

New since the scalar-intrinsics preview: `.del`, `.ins` and `.rep` edit body lines transactionally. `.list` numbers editable body lines; `.list -n` prints plain standard source. After editing executed source, queries and immediate execution remain blocked until explicit successful `.run` or `.clear`, preventing silent replay of output or random effects. Failed edits preserve source and state. A failed run, even STOP 0, cannot bypass the rebuild gate; neither can save/load. See [editor rules](docs/REPL-EDITOR.md).

Validation: 163 unique transcript tests passed both normally and under Python `-O`, including 30 editor tests; 32 bounds-checked native helper assertions and CLI checks also passed. The runtime is unchanged from the intrinsic preview, whose 286 native programs passed. This increment did not rerun that full native suite or the maintained source suite. Windows remains untested. Exact results are in `PREVIEW-STATUS.json` and `evidence/repl-editor-preview/`.

Still not full ofort parity: retained state is limited to local straight-line scalars and seven unary intrinsics, declarations freeze after execution until reset/edit, and the wrapper is fixed. General source loading, full-program/module input, auto-END, autorun, let/const, rename and runtime state files remain incomplete. Body-relative line numbering and explicit rebuild after edits are documented differences. No binaries are included.

---

The earlier intrinsic-preview README below is historical context. Its statement that editor commands are incomplete describes that older snapshot, not the line-editing functionality added here.

# FortFront REPL scalar-intrinsics preview (complete source)

This ZIP has the changes already applied. Extract into a new directory; no manual patching is required. Build using the existing FPM/Windows workflow. The executable retains its baseline development version; this is not a certified release.

New since the interactive preview: retained scalar expressions accept unary `ABS` for INTEGER/REAL, and `SQRT`, `SIN`, `COS`, `EXP`, `LOG`, `LOG10` for REAL, kinds 4 and 8. Nested admitted calls work in immediate assignments, PRINT and bare queries, without replaying prior effects. Other intrinsic and user-function calls remain excluded from retained sessions. The broader ordinary interpreter remains available through explicit `.run`.

Validation passed: all 286 native programs (including 162 scalar-session API checks), 133 unique focused transcript tests both normally and under Python `-O`, plus 17 CLI limits, 13 step-hint and 11 version-contract checks.

See `PREVIEW-STATUS.json` for exact validation counts and `evidence/repl-intrinsics-preview/` for receipts. This is Linux development validation, not Windows execution or full clean maintained-source certification. Host floating-point trapping builds are not certified; `EXP` overflow checks follow host evaluation.

Persistent state remains limited to straight-line nonallocatable scalars with frozen declarations. Arrays, procedures, control flow, full-program input, broader loading, editor commands, auto-END, autorun and let/const parity remain incomplete. Source loading accepts this REPL's wrapper, not arbitrary programs or runtime state. No binaries are included.

---

The prior interactive-preview README below is historical context. Its statement excluding all expression calls applies to that older snapshot, not this increment.

# FortFront REPL interactive preview (complete source)

This ZIP has the changes already applied. Extract into a new directory; no patching or manual source edits are needed. Build with the existing FPM/Windows workflow. The executable still reports the baseline development version: this is not a certified 0.57 release or the untouched 0.56 release.

New since the scalar-session preview:
- Supported scalar assignments and PRINT execute immediately without replaying prior effects; `--defer-check` keeps them buffered.
- `.vars` inspects retained values after executing admitted pending source once; undefined variables are shown explicitly.
- `.save [file]` writes source without overwriting. `.load file` loads this REPL's own saved wrapper without executing.
- `.quit` autosaves a nonempty buffer to an unused `main*.f90`; `.quit!` exits without saving. EOF still does not save or execute.

Run `ffort.exe` with no filename at a terminal. Use `--repl` for piped sessions. File execution and piped batch source remain supported. See [REPL behavior and limitations](docs/REPL.md) and [source file commands](docs/REPL-SOURCE-FILES.md).

Validation: 113 unique focused transcript tests passed normally and under Python `-O`, plus 17 CLI/resource tests, 13 step-budget checks, 11 version-contract tests and independent live-pipe/combined-command probes. The underlying runtime is unchanged from the previous scalar preview, which passed its 286-native-program run. This increment did not rerun the full maintained source suite or the full native suite. Windows execution remains untested. No binaries are included.

This is not full ofort parity: persistent state is restricted to directly local intrinsic scalars and straight-line statements; expressions cannot call procedures/intrinsics, and declaration layout freezes after execution. General code still requires explicit `.run`. Source loading accepts only this REPL's wrapper. Editing, auto-end, autorun, `let`/`const`, broader source loading and runtime state files remain future work. Source is preserved on failed load; source-save commands never overwrite existing files. See `PREVIEW-STATUS.json` and `evidence/repl-interactive-preview/` for exact evidence.

---

The preceding scalar-preview README is retained below as historical context; its deferred-command and unsupported-command statements describe that older snapshot, not this increment.

# FortFront REPL: retained scalar-session preview

This is complete, buildable source with the changes already applied. No manual
patching or proof companion is needed. Build using the existing FPM/Windows
workflow. The Windows command remains `ffort.exe`; FPM builds
`fortfront-interpreter`. Start without a filename on a terminal, or use `--repl`
for a piped session.

## New: bare expressions without replay

```text
> integer :: n
> n = 2
> n*n
 4
> n = n+1
> n
 3
> n
 3
> .quit
```

Pending statements execute once when a valid bare expression is evaluated.
Scalar values and the interpreter RNG state are retained. Queries are temporary:
they are not stored in source, and they do not replay earlier output or random
draws. `.run` deliberately starts a fresh whole-buffer execution. `.list`,
`.clear`, `.help`, `.quit` and `.quit!` remain supported.

This first persistent subset is straight-line, local, nonallocatable scalar
INTEGER, REAL, LOGICAL and fixed-length CHARACTER, with admitted arithmetic,
comparison and logical expressions. It excludes query function calls, arrays,
procedures, loops, initialized declarations and parameters. Declarations freeze
after execution; `.clear` begins a new layout. Runtime failures require explicit
reset. General supported Fortran can still use `.run`, but unsupported persistent
buffers cannot later be silently replayed by a query. See [the exact contract,
budgets and failure rules](docs/REPL.md).

This is not full ofort parity. Assignments and PRINT remain buffered rather than
immediate; invalid query syntax is checked before pending effects. `.vars`,
load/save, automatic saves and editor commands are still unsupported.

## Verification and status

The final development candidate passed all **286 native FPM test programs**,
including **64 scalar-session API checks**; **26 independent session transcript
tests** (also repeated under Python `-O`) and all **32 earlier REPL tests** passed.
The established CLI checks passed (17 resource and 13 step-budget checks), along
with 11 mocked version-contract tests. Independent runtime, REPL and final
verification reviews passed; reproduced failures and their fixes are preserved
under `docs/verification/repl-session-preview/`.

**Development preview, not a certified release.** The full maintained source
contract suite has not been rerun, and Windows execution remains untested. The
version/banner still identifies the 0.56.0 baseline during development; this
modified tree is not the certified 0.56 delivery. No interpreter binary or build
cache is included. Historical proof links may require earlier companions, but
no companion is required to build or run this source.

Typical FPM build and focused test commands (executable path varies by platform):

```text
fpm build --profile debug
python tests/repl/test_repl.py --candidate PATH_TO_EXECUTABLE --report NEW_INITIAL_REPORT.json
python tests/repl/test_session.py --candidate PATH_TO_EXECUTABLE --report NEW_SESSION_REPORT.json
```

## Historical initial-preview README, unchanged below

The following describes the separately delivered first preview and earlier
history, not the new scalar-session feature scope.

# FortFront initial REPL: complete-source development preview

This is a standalone, buildable source preview with the REPL changes already
applied. No patching, source editing, or proof companion is needed to build it.
Use the existing FPM/Windows build workflow. The Windows executable remains
`ffort.exe`; the FPM executable is named `fortfront-interpreter`.

On a terminal, start `ffort.exe` without a filename. Use `--repl` for piped
interactive commands. Enter standard Fortran program-body lines, then `.` or
`.run`. Supported commands: `.run`, `.list`, `.clear`, `.help`, `.quit`, `.quit!`.
`--nologo` and `--prompt TEXT` control the display. See [REPL behavior and
limits](docs/REPL.md) before using it.

This first increment follows ofort's deferred source-buffer workflow, not its
complete interactive feature set. It has no retained-state expression queries,
`.vars`, load/save, automatic saves, autorun, or full program/module input.
Each explicit `.run` starts fresh; queries never replay previous effects.

Validation: 32 unique independent transcript tests passed, including real Linux
PTY entry; the same tests passed under Python `-O`. The existing CLI/resource,
step-budget and version-contract checks passed (17, 13 and 11 respectively).
Independent final code review and boundary probes passed. Current receipts are
under `docs/verification/repl-preview/`. Compiled binaries/build caches are absent.

**This is not a certified release.** Full maintained-suite certification has not
been rerun for this preview. Windows console code is included, but actual Windows
execution is untested. The version/banner intentionally remains the 0.56.0
baseline during this preview; do not identify this modified tree as the certified
0.56 delivery. Historical proof links below require the original 0.56 companions,
which are not required to build or run this preview.

Typical FPM build and focused check (the executable path is platform-dependent):

```text
fpm build --profile debug
python tests/repl/test_repl.py --candidate PATH_TO_EXECUTABLE --report NEW_REPORT.json
```

## Historical 0.56 README, unchanged below

The following describes the separately delivered and certified 0.56 checkpoint,
not the modified REPL preview.

# FortFront interpreter prototype 0.56.0

Bounded internal list-directed READ now accepts one complete local fixed-length CHARACTER array element. See [scope](docs/INTERNAL-READ-ELEMENT.md), [release notes](docs/RELEASE-0.56.md) and [verification](docs/VERIFICATION.md).

The fresh-source, empty-cache Linux GNU Fortran 14.2 debug maintained run passed 11,625 source contracts across 201 suites: 10,865 direct GNU checks, 83 lowered SIMPLE checks and 677 GNU skips, with zero failed contracts. It passed 285 native programs and 397 verifier commands, with 7 separately reported static/shared comparisons and 2,885 unittest-method executions. Direct GNU checks include execution, compile-only and required rejections; they do not imply universal execution equality.

The separate fresh identity-bound M_intrinsics survey retains 74 ordinary complete passes. All 249 normalized check comparisons and 79 prior deterministic run comparisons match 0.55. Timing-sensitive streams remain separately classified; this survey is not included in maintained-suite totals.

The reduced utilities working copy stops at 3084:47 on an internal READ section target. The untouched original remains blocked at 9329:55 by the array-size cap. Neither full source is claimed to execute successfully.

Three disjoint source/current-proof/historical-proof parts share one root; see [delivery](DELIVERY.md). Archive identity and reconstruction are separately recorded delivery gates.

## Historical delivered 0.55 checkpoint (verbatim)

The following describes 0.55 and earlier history, not current measurements.

# FortFront interpreter prototype 0.55.0

This checkpoint adds bounded external literal `(A)` READ into one complete scalar default-CHARACTER array element. The clean Linux GNU Fortran 14.2 debug maintained run passed 11,574 source-contract outcomes across 200 suites and 282 native programs, plus 7 separately reported static/shared comparisons. See [release scope](docs/RELEASE-0.55.md), [READ-element contract](docs/EXTERNAL-READ-ELEMENT.md) and [measured verification](docs/VERIFICATION.md).

The fresh identity-bound M_intrinsics survey checked 249 pinned sources and ran 79 deterministic examples. It retains 74 ordinary complete GNU-agreeing passes with the same classification as 0.54. This is a separately measured run with its own identity and timing, not a new aggregate maintained-test count; its other categories remain separate.

The authorized reduced utilities working copy stops at 3000:27, internal READ from a CHARACTER array-element input file. The untouched original remains blocked at 9329:55 by the array-size cap. Neither full source is claimed to execute successfully in FortFront.

Use both disjoint ZIPs with the common `fortfront-interpreter-0.55.0/` root for all proof. The main source is build-ready without the companion, subject to documented toolchain prerequisites. All `docs/verification/` material, including historical proof, is in the companion. See [delivery](DELIVERY.md).

## Historical delivered 0.54 checkpoint

The following 0.54 text is preserved verbatim as historical context, not a 0.55 certification or delivery claim.

# FortFront interpreter prototype 0.54.0

This checkpoint adds bounded registered-input `INQUIRE(UNIT=..., NAME=...)`, `F0.d` real output, and scalar CHARACTER array-element substring reads, assignments and read-only actual arguments. External READ into an array element remains excluded.

The clean Linux GNU Fortran 14.2 debug run passed 11,507 maintained source-contract outcomes across 199 suites, 281 native programs and 7 separately reported static/shared comparisons. Source outcomes include expected rejections and compile-only checks, not universal execution equality. The fresh reconstructed M_intrinsics survey retains 74 ordinary complete GNU-agreeing examples; its other categories remain separate. The authorized utilities working copy stops at 2995:41 (formatted READ into a CHARACTER array element), while the untouched original stops at 9329:55 (array-size cap). Neither is claimed as a successful whole-source FortFront execution.

Delivery uses two disjoint ZIPs with a common project root: the main ZIP contains source/tests/manuals; the verification companion adds all current proof. Extract both into the same parent directory for the complete audited evidence set. See [delivery](DELIVERY.md), [measured verification](docs/VERIFICATION.md), and [bounded release scope](docs/RELEASE-0.54.md).

Historical 0.53 checkpoint (not a 0.54 certification claim): The clean maintained run passed all 11,389 source-contract outcomes across 195 suites, with 277 native test programs and 7 separately reported static/shared comparisons. It also passed 2,575 Python test methods and 10,566 separately counted integer-mask assertions. The separate fresh reconstructed M_intrinsics survey recorded 74 ordinary GNU-agreeing complete examples out of 249 pinned sources; its remaining categories are reported separately. Expected rejections, compiler differences and separately validated survey categories are not ordinary successful Fortran executions. The authorized utilities working source remains blocked by INQUIRE at 2992:1, while the untouched original retains its array-cap boundary at 9329:55; fresh clean confirmation is recorded in [verification](docs/VERIFICATION.md). INQUIRE, F0.d, array-element substrings, scatter and effect-policy relaxation are not part of this release. See [release scope](docs/RELEASE-0.53.md) and [delivery instructions](DELIVERY.md).

Bounded GETCWD and GET_COMMAND_ARGUMENT process queries support the unchanged exe_name utility body. The interpreted argument zero is the source filename; no interpreter options are exposed. See [process queries](docs/PROCESS-QUERIES.md) for storage, purity, status and full-source limits.

Whole default-CHARACTER variables and arrays support scalar `%LEN` type-parameter inquiries, including undefined and empty data. See [CHARACTER %LEN](docs/CHARACTER-LEN-INQUIRY.md) for the bounded syntax, deferred-length rules and verification.

Bounded INTEGER(4/8) IAND, IOR, IEOR, NOT, BTEST and metadata-only BIT_SIZE support checked scalar/rank-one through rank-three operations. See [integer bits](docs/INTEGER-BITS.md) for exact kinds, shapes, original-demo prerequisites and oracle boundaries.

A small, **actual tree/bytecode interpreter written in Fortran**. It executes a deliberately restricted subset of free-form Fortran, using a pinned, locally patched FortFront frontend and a separate typed execution representation. It does not invoke a compiler to execute source. GNU Fortran is used to build the interpreter and as an independent test oracle.

This is a prototype, not a full modern Fortran implementation, production sandbox, or replacement for an established compiler. Its intentionally narrow source contract is below. Unsupported source is normally rejected during checking; documented runtime domain, input and resource restrictions may reject after earlier statements have completed.

## Allocation error messages and transfer

Bounded ALLOCATE/DEALLOCATE ERRMSG preserves successful message state and reports
allocation failures into fixed/assumed-length CHARACTER storage. Two-argument
MOVE_ALLOC transfers supported numeric, LOGICAL and CHARACTER allocation ownership,
bounds and definedness, including scalar CHARACTER. See
[ERRMSG](docs/ALLOCATION-ERRMSG.md) and [MOVE_ALLOC](docs/MOVE-ALLOC.md) for the exact
subset, resource limits, original demos and separated GNU/safety evidence.

## Version 0.46 additions

This checkpoint adds bounded array-constructor implied-DOs, LBOUND/UBOUND vectors and constant KIND selection, default-CHARACTER MIN/MAX, and ISO_FORTRAN_ENV OUTPUT_UNIT imports usable by staged WRITE. A separate correction restores scalar NORM2 broadcasting within surrounding array expressions. Exact original and authorized working utility sources are preserved. Validation status and known GNU CHARACTER MIN/MAX defects are reported separately; independent-oracle matches are not claimed as GNU agreement.

## Version 0.45 additions

LGE, LGT, LLE and LLT provide bounded default-CHARACTER ASCII comparisons with blank padding. Numeric rank-two TRANSPOSE and scaled REAL NORM2 reductions retain checked metadata, shapes, finite results and separate work/storage limits. T, TL and TR edit descriptors support bounded positioning and backward overwrite, including shared nonadvancing records.

Explicit read-only external `(A)` records and mixed numeric/CHARACTER internal list input are supported. External units are opt-in `--input UNIT=PATH` bindings, never host Fortran units or stdin. GETCWD and GET_COMMAND_ARGUMENT use the documented interpreted process context. See [input](docs/EXTERNAL-READ.md), [process queries](docs/PROCESS-QUERIES.md), [lexical comparisons](docs/LEXICAL-COMPARISONS.md), [matrix operations](docs/MATRIX-NORM.md) and [positioning](docs/POSITION-FORMATS.md) for exact bounds and oracle caveats.

The portable verification command remains unchanged. Linux GNU certification uses `python3 scripts/verify.py --split-debug --shared-native`: separate debug information and one shared native-test library retain every ordinary FPM debug check; the app remains statically linked. See [build profiles](docs/DEBUG-BUILD-PROFILE.md). Windows source support includes the guarded C input loader, but Windows execution has not been verified.

## Version 0.44 additions

Output implied-DO lists compose with scalar/array items, nested counters and atomic output staging. Whole scalar CHARACTER runtime formats and bounded named UNIT/FMT controls support internal and stdout WRITE. Literal ADVANCE='NO' preserves a shared output record across statements and calls without adding a final newline. The unchanged join-family utility bodies, integer_label, str_real and str_concat are tested separately from the full library.

Bounded REAL(4/8) ACOSD, ASIND, SIND and COSD preserve finite-input and signed-zero contracts. Whole CHARACTER `%LEN` inquiries reuse checked scalar length metadata without reading undefined element values. See [output lists](docs/OUTPUT-IMPLIED-DO.md), [runtime formats](docs/RUNTIME-FORMATS.md), [degree intrinsics](docs/DEGREE-TRIGONOMETRY.md) and [CHARACTER length](docs/CHARACTER-LEN-INQUIRY.md).

CLI step-limit errors report the selected limit and the `--max-steps N` option while the reusable API diagnostic and source location stay unchanged. The normal-mixture command remains `ffort.exe --max-steps 100000000 ..\xmix_dt.f90`.

At the user's request, a separately labeled [utility working copy](tests/utilities_working/xutilities-nmax-100000.f90) changes only `nmax=10**8` to `nmax=10**5`. The original remains byte-identical. This source adaptation does not change the interpreter's one-million-element cap or imply full-library support; working-copy and original outcomes are reported separately.

## Version 0.43 additions

This checkpoint adds bounded defined CHARACTER `+` signatures, scalar allocatable CHARACTER storage and calls, and internal list-directed READ from a scalar CHARACTER variable into supported whole numeric targets. External input is bounded and explicitly bound as described above. READ error/EOF definedness and IOSTAT behavior are checked; error branches that read undefined results are not claimed as GNU execution agreements.

DIGITS, NEW_LINE and RRSPACING support their documented bounded kinds, shapes and metadata-only inquiries. Colon edit descriptors terminate formatted output when no items remain, composing with ordinary and unlimited-repeat formats. Complete unchanged examples and original utility bodies are tested separately from synthetic composition and safety cases.

A parser correction keeps quoted punctuation such as `'['` and `'('` as CHARACTER data and prevents quoted closing delimiters from satisfying grammar. The unchanged combined fixtures and malformed-source checks are documented in [punctuation literals](docs/PUNCTUATION-LITERALS.md).

See [CHARACTER operators](docs/CHARACTER-PLUS.md), [scalar allocation](docs/SCALAR-ALLOCATABLE-CHARACTER.md), [internal READ](docs/INTERNAL-READ.md), [model/character intrinsics](docs/MODEL-CHARACTER-INTRINSICS.md), [colon formats](docs/COLON-FORMATS.md) and [verification](docs/VERIFICATION.md). The default one-million-element cap and separate work/output/CHARACTER limits remain unchanged; full utility-library execution is not claimed.

## Version 0.42 additions

The default array-storage, result and actual-argument cap is 1,000,000 elements. A single named build-time constant controls the limit; a 10,000,000-element build is an opt-in high-memory configuration. Compact scalar values allocate derived-record payloads only when needed, retaining deep-copy value semantics. The cap is per live storage region, not a process-memory budget. Work-step, CHARACTER-byte and output limits remain separate. See [array capacity](docs/ARRAY-LIMITS.md) for configuration and measured costs.

Mandatory rank-one through rank-three ALLOCATABLE CHARACTER dummies now admit bounded specification lengths such as LEN(words). Entry freezes the length after input association and requires an exact nondeferred actual-length match, including empty and unallocated actuals. The original compress routine is exercised without body changes. See [specification-length CHARACTER](docs/ALLOCATABLE-CHARACTER-LENGTHS.md) for supported forms and exclusions.

The complete supplied normal-mixture program remains covered by explicit 100-million-step acceptance runs. The complete untouched utility module still rejects its 100-million-element declaration; full-library execution is not claimed. See [verification](docs/VERIFICATION.md) for final build, test and profiling evidence.

## Bounded internal READ extension

Scalar CHARACTER internal records support bounded list-directed INTEGER/REAL
input with IOSTAT, null/repetition/slash semantics and checked undefinedness after
input errors. Both original allocating vector readers are exercised unchanged.
External input requires explicit bounded unit bindings for `(A)` records or the documented list-directed subset as described in [the input contract](docs/EXTERNAL-READ.md).

## Build and run

Requirements: GNU Fortran supporting Fortran 2018, a C compiler (gcc/clang or the matching MinGW toolchain), fpm, and Python 3 for the independent differential suite. The recorded verification uses GNU Fortran 14.2.0 and fpm 0.13.0 alpha on Linux x86-64. No network download is needed: the exact FortFront library sources are included with their MIT license.

```sh
fpm build
fpm run fortfront-interpreter -- examples/sum_squares.f90
fpm run fortfront-interpreter -- examples/implicit_main_power.f90
fpm run fortfront-interpreter -- examples/parameter_sum.f90
fpm run fortfront-interpreter -- examples/whole_arrays.f90
fpm run fortfront-interpreter -- examples/array_sections.f90
fpm run fortfront-interpreter -- examples/module_functions.f90
fpm run fortfront-interpreter -- examples/module_subroutine.f90
fpm run fortfront-interpreter -- examples/black_scholes.f90
fpm run fortfront-interpreter -- examples/argument_association.f90
fpm run fortfront-interpreter -- examples/matrix_multiply.f90
fpm run fortfront-interpreter -- examples/array_intrinsics.f90
fpm run fortfront-interpreter -- examples/keyword_arguments.f90
fpm run fortfront-interpreter -- examples/pure_simple.f90
fpm run fortfront-interpreter -- examples/elemental_functions.f90
fpm run fortfront-interpreter -- examples/elemental_subroutines.f90
fpm run fortfront-interpreter -- examples/mean_constructor.f90
fpm run fortfront-interpreter -- examples/mean_random.f90
fpm run fortfront-interpreter -- examples/mean_random_power.f90
fpm run fortfront-interpreter -- examples/random_summary_100000.f90
fpm run fortfront-interpreter -- examples/month_date.f90
fpm run fortfront-interpreter -- examples/select_case.f90
fpm run fortfront-interpreter -- examples/character_arrays.f90
fpm run fortfront-interpreter -- examples/generic_twice.f90
fpm run fortfront-interpreter -- examples/month_date_class.f90
fpm run fortfront-interpreter -- tests/release_integration/utilities_combined_020.f90
fpm run fortfront-interpreter -- --check examples/sum_squares.f90
fpm run fortfront-interpreter -- --max-steps 100000 examples/sum_squares.f90
fpm test
python3 scripts/verify.py
```

On Windows, put GNU Fortran, fpm and Python 3 on PATH, then use the same `fpm`
commands and `python scripts/verify.py` (or `powershell -File scripts/verify.ps1`).
The verifier uses Python paths/process APIs, not `find`, `realpath`, or Bash.
The implementation has no POSIX-specific runtime dependencies. **Windows has not
been executed in the recorded verification**; this is a portable source package,
not a prebuilt Windows binary. If upgrading an older checkout, remove its build
cache or run `fpm clean --all` before building, so stale module callers are not linked.

`--check` parses, checks types and the supported boundary, and cross-validates the FortFront tree without running the program. It does not prove that execution will avoid uninitialized reads, arithmetic errors, or the execution limit.

The executable returns 0 for success and normal no-code/CHARACTER STOP, 1 for source/options/frontend errors, and 2 for checked execution errors. Supported integer STOP codes return the explicitly requested status from 0 through 255. STOP diagnostics go to stderr and unwind all active calls without executing later statements. Diagnostics are written to stderr with source path, line and column where known. Check mode emits no program output. `--help` and `--version` are available.

## Version 0.38 milestone

Intrinsic ISO_FORTRAN_ENV ONLY imports now support bounded local aliases with
exact remote identity checks. REAL128=-1 truthfully reports an unsupported
precision; this does not enable REAL(16) values.

ERFC_SCALED supports REAL(4/8) elemental execution with stable positive
subnormal tails and guarded finite negative endpoints. Two-argument ASSOCIATED
compares ordered storage identity without reading pointee values. CSHIFT supports
bounded rank-one/rank-two circular shifts with scalar or conforming array SHIFT.
Existing lifetime, kind, shape, purity, finite-value and resource checks remain.

See [ISO aliases](docs/ISO-FORTRAN-ENV-ALIASES.md),
[ERFC_SCALED](docs/ERFC-SCALED.md), [ASSOCIATED](docs/ASSOCIATED-TARGET.md),
[CSHIFT](docs/CSHIFT.md) and [verification](docs/VERIFICATION.md). Complete original
programs, synthetic composition tests and independent mathematical oracles are
reported separately. Known GNU endpoint, empty-array and optional-target
limitations are explicitly recorded rather than treated as execution agreement.

The unchanged full xutilities file still stops at 9329:55: xbig(nmax) declares
nmax=10**8, above the default 1,000,000-element cap. The separately authorized
working copy changes only that declaration to nmax=10**5. With the 0.53
numeric rank-one gather and read-only bare-actual additions, the adapted working
source boundary advanced to 2992:1, unsupported `INQUIRE`, in that historical
checkpoint. Bounded registered-input NAME inquiry now advances the focused
0.54 source gate to 2995:41, external READ to a CHARACTER array element. Both
checking and the run command still reject before interpreted execution. Whole-file support
remains incomplete; the original source and the authorized one-byte adaptation
are preserved. External input is limited to explicit bound records; CLOSE and general file I/O remain unsupported.

## Supported source contract

Mandatory ALLOCATABLE IN/INOUT dummies support bounded SIZE/LBOUND/UBOUND
specification inquiries with entry-time allocation checks and frozen local shapes.
See [ALLOCATABLE-SPEC-INQUIRIES.md](docs/ALLOCATABLE-SPEC-INQUIRIES.md).

**Rank-three extension:** intrinsic explicit/automatic arrays, assumed-shape dummies,
ordinary array results, sections, elemental operations and scalar-DIM inquiries now
support up to three dimensions. See [docs/RANK-THREE.md](docs/RANK-THREE.md) for
this extension to the rank-one/rank-two descriptions below. Numeric and CHARACTER
allocatables now support rank three, including module variables, descriptor dummies,
assignment reallocation and function results; see
[rank-three allocatables](docs/RANK-THREE-ALLOCATABLES.md).
PACK, RESHAPE, reductions and matrix products retain their existing rank limits.


- Zero or more same-file modules before one main program. Modules support scalar and supported rank-one/rank-two PARAMETER and mutable intrinsic data, PUBLIC/PRIVATE accessibility and explicit intrinsic ISO_FORTRAN_ENV ONLY imports. REAL32/REAL64 and INT32/INT64 support local aliases such as `dp => real64`; REAL128=-1 truthfully reports an unsupported REAL kind. See [ISO aliases](docs/ISO-FORTRAN-ENV-ALIASES.md). Main programs and later same-file modules support plain USE or USE ONLY (without renaming or re-export). Module data and imports are available to their contained procedures, with one shared mutable store per execution. See [docs/MUTABLE-MODULES.md](docs/MUTABLE-MODULES.md). Internal main-program procedures inherit its PARAMETER constants and USE associations, but not mutable host variables.
- Same-file procedure organization: Modules have an optional `implicit none`, declarations/accessibility, an optional `contains` section, and functions or subroutines with scalar or rank-one/rank-two dummy arguments. The main program may have a CONTAINS section with internal procedures. Non-ELEMENTAL module procedures can also contain one level of internal procedures with bounded host association, sibling calls and explicit recursion; see [docs/INTERNAL-PROCEDURES.md](docs/INTERNAL-PROCEDURES.md). See [docs/MODULES.md](docs/MODULES.md).
- Named module generic interfaces group module functions or subroutines and select one specific by exact type, INTEGER/REAL kind, rank and keyword association. PUBLIC/PRIVATE, USE ONLY, private specifics through a public generic, and supported ELEMENTAL lifting compose with this rule. External/interface-body procedures and generic merging across modules remain excluded. See [docs/GENERIC-PROCEDURES.md](docs/GENERIC-PROCEDURES.md).
- One main program, with an optional `program name` header and optional `implicit none` before declarations. Finish with `end` or `end program [name]`. An ending name requires an explicit, matching header. Blank lines and comments may intervene. Omitting the header is standard Fortran's implicit main program; implicit variable typing remains outside this subset.
- ASCII free-form source; at most 1,048,576 bytes (1 MiB), 132 columns per non-comment line. Case-insensitive identifiers, `!` comments, and semicolon statement separators, and free-form continuation between complete tokens with a trailing `&` and optional leading `&` on the next nonblank source line. Blank/comment-only intervening lines are skipped.
- Scalar functions use `function name(arguments)` with an optional `result(result_name)` clause. Without RESULT the function name is the result variable. The result has either an explicit declaration or a typed header such as `real(dp) function ... result(...)`. Typed headers require literal/named kind selectors; direct KIND and SELECTED_REAL_KIND selectors are supported in declarations only. PURE and Fortran 2023 SIMPLE designations are accepted, before or after the result type. SIMPLE implies PURE and requires every referenced user procedure to be designated SIMPLE; PURE requires PURE or SIMPLE callees. Redundant PURE SIMPLE is accepted, but duplicate copies of a prefix are rejected. See [docs/PURE-SIMPLE.md](docs/PURE-SIMPLE.md). Function arguments are positional or keyword INTEGER, REAL or LOGICAL scalars or rank-one/rank-two assumed-shape arrays declared INTENT(IN). Subroutines use `subroutine name(arguments)` and CALL, with scalar or rank-one/rank-two INTENT(IN/OUT/INOUT) arguments; IN OUT is accepted as the two-word spelling of INOUT; scalar and rank-one/rank-two CHARACTER dummies support fixed or assumed length and IN/OUT/INOUT. Bounded runtime local/result lengths and CHARACTER array results are covered in [docs/CHARACTER-PROCEDURES.md](docs/CHARACTER-PROCEDURES.md). Scalar derived-type arguments use the restrictions described below. Ordinary procedure arguments require exactly matching types, INTEGER/REAL kinds and ranks; unlike assignment, no implicit numeric conversion is made at a call. Procedure bodies can use scalar or explicit-shape rank-one/rank-two locals, parameters, assignment, IF/DO/SELECT CASE, RETURN, STOP, ERROR STOP and sibling functions (including later definitions). Calls can appear in expressions and PRINT items. Array expression actuals, including REAL64 `mean(x**2)`, retain declaration-resolved type/kind/rank during strict call checking; no implicit actual-to-dummy kind conversion is introduced.
- Explicit `RECURSIVE` ordinary functions/subroutines support direct and mutual recursion with independent activation storage, existing alias/purity checks, a shared work budget and a 64-frame limit. All cycle participants must carry RECURSIVE; RECURSIVE ELEMENTAL is excluded. See [docs/RECURSION.md](docs/RECURSION.md).
- Ordinary non-ELEMENTAL functions can return explicit-shape rank-one/rank-two INTEGER(4/8), REAL(4/8), LOGICAL or default CHARACTER arrays. Constant and bounded dummy-dependent result shapes, expression operands, reductions, constructors and read-only array actuals are supported. Results own their storage and must be fully defined on return. See [docs/ARRAY-RESULTS.md](docs/ARRAY-RESULTS.md).
- Pure `ELEMENTAL` functions have scalar INTEGER/REAL/LOGICAL INTENT(IN) dummies and a scalar result declaration. Scalar actuals produce a scalar call; conformable rank-one/rank-two actuals lift the call result element by element, with scalar expansion. Sections, keyword arguments, empty arrays, nested calls and overlap-safe assignment compose with this rule. ELEMENTAL implies PURE, and may be combined with explicit PURE or SIMPLE in any supported prefix order. See [docs/ELEMENTAL-FUNCTIONS.md](docs/ELEMENTAL-FUNCTIONS.md).
- `ELEMENTAL` subroutines support scalar IN/OUT/INOUT dummies with conformable rank-one/rank-two actuals. Writable actuals must all be arrays when any actual is an array; scalar IN arguments expand. Explicitly `IMPURE ELEMENTAL` functions/subroutines support ordered element execution and PRINT side effects, with checked recursive-I/O rejection. Functions retain IN-only dummies. See [docs/ELEMENTAL-SUBROUTINES.md](docs/ELEMENTAL-SUBROUTINES.md).
- Default `integer`, `real`, and `logical` scalars, INTEGER(kind=4/8), plus REAL with a literal, named INTEGER PARAMETER or direct KIND/SELECTED_REAL_KIND inquiry selector evaluating to 4 or 8, as scalars and explicit-shape rank-one and rank-two arrays, declared before all executable statements. The `::` separator is optional when there are no declaration attributes or initializers; see [docs/OPTIONAL-COLONS.md](docs/OPTIONAL-COLONS.md). Mixed and multiple declarators are supported, for example `integer :: i, a(5), b(-2:2), matrix(-1:1,4)`. Main-program scalar and array initializers must be constant expressions; arrays support scalar expansion or a conformable array expression. Every name must be explicitly declared, unique, and at most 63 characters.
- Elemental INDEX, LEN_TRIM, ADJUSTL and ADJUSTR support scalar and rank-one/two default CHARACTER, keyword arguments, empty arrays, and INTEGER(4/8) search/length results. Bounded LEN_TRIM-based specification expressions execute the unchanged original utility `quote` routine. See [docs/CHARACTER-INTRINSICS.md](docs/CHARACTER-INTRINSICS.md).
- Inferred-length default `CHARACTER(*), PARAMETER` constants take each entity's own initializer length, including supported rank-one/two arrays and zero-sized typed constructors. Supported constant expressions include TRIM, concatenation, prior constants, CHAR and ACHAR. See [docs/CHARACTER-PARAMETERS.md](docs/CHARACTER-PARAMETERS.md).
- Scalar and supported rank-one/rank-two named constants use `integer, parameter :: n=10`, or the corresponding `real`/`logical` form. Each declarator requires a constant initializer; expressions can reference previously defined parameters, including earlier declarators on the same line. The declared type controls numeric conversion. Parameters are immutable and cannot be DO control variables.
- Bounded PURE specification functions support direct, earlier-declared module functions with mandatory scalar INTEGER(4/8) inputs/results in automatic bounds and runtime CHARACTER lengths. No user-defined constant expressions are introduced. See [docs/SPECIFICATION-FUNCTIONS.md](docs/SPECIFICATION-FUNCTIONS.md).
- Each array dimension uses `upper` or `lower:upper`, as in `a(upper)`, `a(lower:upper)` or `a(-1:1,2:4)`, with scalar INTEGER constant expressions (including earlier parameters and supported pure intrinsics), or supported dummy-dependent specification expressions for procedure-local automatic arrays. Automatic bounds are evaluated once on entry after dummy association; their storage shares the existing per-frame limit. See [docs/AUTOMATIC-ARRAYS.md](docs/AUTOMATIC-ARRAYS.md). The default lower bound is 1. Negative/non-unit lower bounds and zero-sized arrays are valid. Other variable bounds and unlisted declaration attributes are outside this release. Bounded TARGET declarations are preserved independently of pointer support. Assumed-shape dummy arrays use `a(:)`, `a(constant_lower:)`, `a(:,:)` or constant lower bounds on either dimension; see [docs/ARGUMENT-ASSOCIATION.md](docs/ARGUMENT-ASSOCIATION.md).
- Numeric, LOGICAL and default CHARACTER rank-one/rank-two/rank-three allocatable local/module arrays support ALLOCATE, DEALLOCATE, ALLOCATED, bounded STAT recovery, descriptor-preserving IN/OUT/INOUT dummies, intrinsic assignment reallocation and allocatable function results. See [docs/ALLOCATABLES.md](docs/ALLOCATABLES.md) and [docs/ALLOCATABLE-CHARACTER.md](docs/ALLOCATABLE-CHARACTER.md).
- Rank-one array constructors `[values]` and `(/values/)` concatenate INTEGER, REAL, LOGICAL or descriptor-known CHARACTER scalar/rank-one expressions. Numeric/logical items require matching types and kinds; untyped CHARACTER items require matching fixed or supported descriptor-known runtime lengths. Typed CHARACTER constructors explicitly pad/truncate item lengths and permit empty constructors. Empty typed INTEGER/REAL kind4/8 and default LOGICAL constructors are supported; nonempty numeric/logical typed constructors, untyped empty constructor syntax remain unsupported; bounded constructor implied-DOs are supported with separate statement-local indices and eager source-order snapshots. See [docs/MEAN-PROGRAMS.md](docs/MEAN-PROGRAMS.md) and [docs/CHARACTER-ARRAYS.md](docs/CHARACTER-ARRAYS.md).
- `kind(x)` or `kind(x=x)` returns the supported declared kind without evaluating its scalar/array argument, including undefined variables and function expressions. It is valid in constant expressions even when its argument is not constant. Supported INTEGER kinds are 4/8, LOGICAL is 4, CHARACTER is 1, and REAL is 4/8.
- `EPSILON`, `TINY`, `HUGE` and `RADIX` are scalar, metadata-only numeric-model inquiries, including for array arguments. REAL(4/8) is supported; HUGE/RADIX also accept INTEGER(4/8). Undefined data, absent OPTIONAL dummies and unallocated/disassociated arrays do not require value evaluation. See [numeric model inquiries](docs/NUMERIC-MODEL-INQUIRIES.md).
- Numeric `TRANSPOSE(MATRIX)` supports rank-two INTEGER/REAL kind 4/8. Scaled `NORM2(X [, DIM])` supports REAL kind 4/8, rank one through three, dynamic DIM, empty arrays and metadata-only KIND inquiries. See [matrix transformations and norms](docs/MATRIX-NORM.md) for bounds, finite-result policy and independent tiny-value oracles.
- `CSHIFT(ARRAY, SHIFT [, DIM])` stages circular shifts of intrinsic rank-one/rank-two arrays, with scalar or conforming rank-one INTEGER(4/8) shifts, dynamic DIM, sections and alias-safe assignment. Fixed CHARACTER lengths and temporary bounds are checked. See [CSHIFT](docs/CSHIFT.md).
- `call random_number(harvest)` or `call random_number(harvest=harvest)` fills writable REAL scalar/rank-one/rank-two/rank-three variables, elements or sections. It is impure and uses a documented, deterministic per-execution pseudorandom sequence. Ordinary impure functions may use this stream while retaining shared-storage and I/O restrictions; see [the RNG contract](docs/MEAN-PROGRAMS.md) and [function evaluation boundaries](docs/RANDOM-FUNCTIONS.md).
- `call random_seed()` or `call random_seed` resets the shared execution-owned pseudorandom stream to processor-selected state 104729. Only the no-argument form is supported; SIZE/PUT/GET and RANDOM_INIT remain outside the subset. PURE/SIMPLE procedures cannot reset the stream. See [RANDOM-SEED.md](docs/RANDOM-SEED.md).
- Array elements `a(index)` or `matrix(i,j)` can be assigned, printed or used wherever a scalar expression is allowed, including IF/DO expressions, intrinsic arguments and nested subscripts such as `a(indices(i))`. Subscripts must be scalar INTEGER expressions.
- Whole-array assignment supports scalar expansion and conformable rank-one/rank-two expressions. Arithmetic, comparisons, logical operations and the supported elemental intrinsics act element by element. Conformance requires equal rank and equal extent in every dimension, not equal lower bounds or merely equal total size. Whole-array PRINT expands in Fortran column-major order (first subscript varies fastest).
- Rank-one/rank-two sections `a(lower:upper:stride)`, `matrix(:,j)`, `matrix(i,:)` and `matrix(l1:u1:s1,l2:u2:s2)` support omitted endpoints and default stride 1, scalar INTEGER runtime triplet expressions, scalar expansion, elemental expressions and PRINT. Omitted endpoints always use the declared lower/upper bounds, even for negative stride; use explicit `a(upper:lower:-1)` for reversal. Scalar subscripts reduce rank, and each triplet preserves one dimension. Section extents and conformance are checked at runtime. See [docs/RANK-TWO-SECTIONS.md](docs/RANK-TWO-SECTIONS.md).
- Array inquiries `size(array[,dim])`, `lbound(array,dim)` and `ubound(array,dim)` return scalar INTEGER results; DIM must be between 1 and the array rank. SIZE without DIM returns total elements; with DIM it returns that dimension's extent. Bound inquiries use the requested dimension, including per-dimension empty bounds. They inspect shape without reading element values. ARRAY and DIM keyword arguments are supported.
- `LBOUND(ARRAY[,DIM,KIND])` and `UBOUND(ARRAY[,DIM,KIND])` return scalar bounds with DIM, or INTEGER(4/8) bound vectors without it, for supported rank-one/two/three intrinsic arrays. Whole-object, normalized expression/section and empty-axis rules are preserved. See [docs/ARRAY-BOUNDS-INQUIRY.md](docs/ARRAY-BOUNDS-INQUIRY.md).
- `SHAPE(SOURCE[,KIND])` returns an INTEGER(4/8) extent vector for intrinsic scalar and rank-one/two/three sources, including allocated numeric/CHARACTER descriptors. It reads shape rather than element values; scalar SOURCE has an empty result. See [docs/SHAPE-INTRINSIC.md](docs/SHAPE-INTRINSIC.md).
- Dummy declaration attributes accept both `INTENT(INOUT)` and `INTENT(IN OUT)`, including supported continuations and intervening comments. Exact direction, alias and purity checks are unchanged. See [docs/INTENT-SPELLING.md](docs/INTENT-SPELLING.md).
- Array reductions `sum`, `product`, `minval` and `maxval` preserve INTEGER/REAL kind on rank-one/rank-two arrays. Positional or keyword DIM and scalar/conformable LOGICAL MASK are supported, including the `(array,mask)` overload. `dot_product` supports rank-one pairs; `matmul` supports matrix/matrix, matrix/vector and vector/matrix pairs. Products accept mixed numeric types/kinds or two LOGICAL operands. Empty reductions/products, expression inputs, sections and assumed-shape arguments are supported. See [docs/ARRAY-INTRINSICS.md](docs/ARRAY-INTRINSICS.md).
- Keyword actual arguments for supported user procedures and array intrinsics, with case-insensitive names, positional arguments before keywords, and independent AST association checks. See [docs/KEYWORD-ARGUMENTS.md](docs/KEYWORD-ARGUMENTS.md).
- Assignment between numeric types, or logical-to-logical assignment. Integer division truncates toward zero. Real-to-integer assignment truncates toward zero with a range check.
- Arithmetic `+ - * / **`, parentheses, numeric comparisons `== /= < <= > >=` and dotted equivalents, and `.not. .and. .or. .eqv. .neqv.` with Fortran precedence. Exponentiation is right-associative. Unary minus binds less tightly than exponentiation.
- Default integer, real (E/D exponents and supported numeric or named kind suffixes), logical, and character literals, with doubled-quote escaping. Fixed-length CHARACTER scalar and explicit-shape rank-one/rank-two variables and parameters support assignment padding/truncation, element/section operations, concatenation and blank-padded comparisons. Scalar/array CHARACTER dummies and results, bounded procedure-local/result lengths, LEN and scalar TRIM are supported. Bounded allocatable/deferred-length CHARACTER arrays are described in [docs/ALLOCATABLE-CHARACTER.md](docs/ALLOCATABLE-CHARACTER.md). Scalar-base substrings are described in [docs/CHARACTER-SUBSTRINGS.md](docs/CHARACTER-SUBSTRINGS.md); scalar array-element substrings are described in [docs/ARRAY-ELEMENT-SUBSTRINGS.md](docs/ARRAY-ELEMENT-SUBSTRINGS.md); array-section bases and writable substring actuals remain unsupported, as do nondefault CHARACTER kinds. See [docs/CHARACTER-ARRAYS.md](docs/CHARACTER-ARRAYS.md).
- Pure elemental intrinsics `abs`, `mod`, `min`, `max`, `exp`, `log`, `sqrt` and `erfc`. MIN/MAX additionally support default CHARACTER, differing lengths, scalar/array expansion and A1–A16 keywords; the other intrinsics in this list do not support KIND or keyword arguments. REAL supports INTEGER(4/8) and REAL(4/8) operands, optional constant KIND=4/8, and positional or keyword A/KIND association; its default result is REAL(4). See [REAL conversion](docs/REAL-CONVERSION.md). INT additionally supports its documented constant KIND and keyword arguments. MIN/MAX and MOD arguments must have matching types and kinds; transcendental arguments must be REAL.
- Real elemental `sinh`, `cosh` and `tanh` preserve REAL(4/8) kind and scalar/rank-one/rank-two shape, including empty arrays and `X=` keywords. Non-finite results are rejected. See [docs/HYPERBOLIC-INTRINSICS.md](docs/HYPERBOLIC-INTRINSICS.md).
- Real elemental `sin`, `cos` and `tan` preserve REAL(4/8) kind and scalar/rank-one/rank-two shape, including sections, empty arrays, constant expressions and `X=` keywords. See [docs/TRIGONOMETRIC-INTRINSICS.md](docs/TRIGONOMETRIC-INTRINSICS.md).
- Elemental `NINT`, `FLOOR` and `CEILING` accept REAL(4/8) scalar/rank-one/rank-two arguments and constant INTEGER result KIND=4/8; `LOG10` preserves REAL kind and shape. Keywords, constants, sections, empty arrays and checked conversion overflow are supported. See [docs/ROUNDING-INTRINSICS.md](docs/ROUNDING-INTRINSICS.md).
- `PACK(ARRAY,MASK[,VECTOR])` accepts rank-one/rank-two INTEGER(4/8), REAL(4/8), default LOGICAL and fixed-length CHARACTER arrays, scalar or conforming array masks, and keyword arguments. It preserves array element order and returns a rank-one result. See [docs/PACK.md](docs/PACK.md).
- `RESHAPE(SOURCE,SHAPE[,PAD,ORDER])` produces bounded rank-one/rank-two intrinsic arrays with a statically known SHAPE length of one or two, runtime extents, repeated PAD values, ORDER permutations and keywords. See [docs/RESHAPE.md](docs/RESHAPE.md).
- `FINDLOC` searches supported rank-one/rank-two INTEGER, REAL, LOGICAL and CHARACTER arrays with scalar VALUE, DIM, MASK, KIND and BACK. It preserves positional coordinates, blank-padded CHARACTER equality and checked masked evaluation. See [docs/FINDLOC.md](docs/FINDLOC.md).
- `MINLOC` and `MAXLOC` support numeric rank-one/rank-two arrays, DIM, scalar/conformable MASK, result KIND and BACK. `DIMENSION(...)` is accepted as an alternative to declarator shapes within existing bounds restrictions. See [docs/LOCATION-INTRINSICS.md](docs/LOCATION-INTRINSICS.md).
- `PARITY` reduces default-LOGICAL rank-one/rank-two masks with optional DIM and a false empty identity. The unchanged upstream PARITY demo runs against GNU. See [docs/PARITY.md](docs/PARITY.md).
- `ALL`, `ANY`, `COUNT` with rank-one/rank-two `DIM`, `COUNT KIND=4/8`, elemental `MERGE` and `DBLE`, including keywords. See [docs/LOGICAL-INTRINSICS.md](docs/LOGICAL-INTRINSICS.md).
- Output implied-DO lists support checked local INTEGER counters, source-order scalar/array items, reverse/empty iteration and eight nested levels, with staged atomic output and explicit value/iteration limits. See [docs/OUTPUT-IMPLIED-DO.md](docs/OUTPUT-IMPLIED-DO.md). Constructor implied-DOs use their separate documented statement-entity semantics; input implied-DOs remain unsupported.
- `print *, items` and empty `print *`. Literal, named scalar CHARACTER PARAMETER and bounded whole scalar CHARACTER runtime formats for PRINT support comma-separated A[width], Iw[.m], Fw.d (including bounded F0.d), Ew.d, ESw.d, Gw.d, Lw and nX descriptors, quoted literals, descriptor repeat counts and bounded nested parenthesized groups. Formatted items may be scalar or supported rank-one/rank-two/rank-three arrays and must match the descriptors after element-order expansion. PRINT reversion starts another record at the last closed inner group, or the start of a flat format; surplus data descriptors terminate normally when the list is exhausted. Bounded slash record edits are supported for external stdout; reached scalar internal/defined-child record advancement remains unsupported. Labels, arbitrary format expressions and arbitrary external units are rejected. See [docs/FORMATTED-ARRAYS.md](docs/FORMATTED-ARRAYS.md) and [docs/GROUPED-FORMATS.md](docs/GROUPED-FORMATS.md). I/O is permitted in main programs, impure subroutines and explicitly IMPURE ELEMENTAL functions, but not PURE/SIMPLE procedures or ordinary functions. Recursive output through PRINT expression evaluation is checked.
- Scalar module-defined derived types support INTEGER/REAL/LOGICAL and fixed-length default CHARACTER scalar components, mixed initialized/uninitialized component lists, bounded constant component defaults and positional constructors with defaulted trailing omissions, component selection/assignment, whole-value copy, scalar TYPE dummies/results and unary/binary module-defined operators. Scalar CLASS dummies of an exact non-inherited type, default-PASS bound methods and bounded defined formatted output through DT/list-directed PRINT are supported. Both requested date programs run unchanged. This does not add inheritance, changing dynamic type or general file I/O. See [docs/DERIVED-TYPES.md](docs/DERIVED-TYPES.md) and [docs/CLASS-TYPE-BOUND.md](docs/CLASS-TYPE-BOUND.md).
- WHERE statements and unnamed WHERE/ELSEWHERE constructs support rank-one/rank-two whole-array and section assignments with frozen masks, selected-element evaluation and per-assignment temporaries. Nested WHERE is excluded; user functions must be PURE. See [docs/WHERE.md](docs/WHERE.md).
- FORALL statements and unnamed constructs support one or two independent INTEGER indices, optional frozen masks and simultaneous array-element/section assignment. Snapshot evaluation, duplicate-target checks, PURE calls and allocation descriptors compose within documented limits. See [docs/FORALL.md](docs/FORALL.md).
- SELECT CASE supports scalar INTEGER, CHARACTER and LOGICAL selectors, constant discrete lists, supported inclusive/open ranges, CASE DEFAULT and nesting. The selector is evaluated once; overlapping/duplicate cases are rejected. Fixed-length character semantics and numeric/logical array PARAMETER values compose with it. See [docs/SELECT-CASE.md](docs/SELECT-CASE.md).
- SELECTED_REAL_KIND supports optional scalar INTEGER P, R and RADIX arguments with keyword association, using the supported REAL32/REAL64 model. Wider GNU Fortran kinds are not added. See [docs/UTILITIES.md](docs/UTILITIES.md).
- INTEGER kinds 4 and 8, SELECTED_INT_KIND, INT with a constant KIND argument and MODULO support the date program's wide arithmetic. Integer operations compare and compute exactly without REAL conversion, with checked signed overflow and narrowing. See [docs/INTEGER-KINDS.md](docs/INTEGER-KINDS.md).
- Positional `write(*,*) items` and `write(*,literal_or_named_parameter_format) items`, including empty item lists, use the same default-output transfer and formatter as PRINT. Records are staged before output. Bounded named UNIT/FMT controls, whole scalar CHARACTER runtime formats and literal ADVANCE=YES/NO extend this path; whole scalar INTEGER(4/8) unit names are additionally admitted only when their once-evaluated value equals OUTPUT_UNIT. Other control specifiers and arbitrary external units remain unsupported. See [docs/STDOUT-WRITE.md](docs/STDOUT-WRITE.md) and [docs/RUNTIME-FORMATS.md](docs/RUNTIME-FORMATS.md).
- Bounded `INQUIRE(UNIT=iu, NAME=name)` copies the supplied name of an explicitly registered read-only input unit into a whole writable local default-CHARACTER scalar. UNIT is a whole INTEGER(4/8) variable; no host discovery, new file opening, cursor/endfile changes or effect-policy relaxation is added. See [INQUIRE NAME](docs/INQUIRE_NAME.md).
- Zero-width `F0.d` output supports finite REAL(4/8), precision 0..1024, with existing staged-record limits; other zero-width descriptor rules and G0 behavior are unchanged. See [F0 formats](docs/F0-FORMATS.md).
- Internal formatted WRITE to a writable scalar CHARACTER variable or one whole CHARACTER element of a rank-one/two/three array supports intrinsic scalar/array items and the bounded shared format grammar with literal, parameter or runtime scalar CHARACTER formats, including quoted literals and Iw.m zero padding. It is limited to one record; reached reversion/slash advancement is rejected. Element indices are evaluated once and the target is committed only after the complete record fits. Element files exclude derived output roots, pointers, sections, substrings, whole arrays and explicit PURE procedures; see [the exact contract](docs/INTERNAL_WRITE_ELEMENT.md). Outside registered defined-output callbacks, nondefault external-unit WRITE and IOSTAT/IOMSG remain unsupported; no file I/O is added. Ordinary functions may perform internal character formatting and call non-I/O helper subroutines while retaining PURE/SIMPLE constraints.
- Single-line IF with a supported action statement, or block IF with ELSE IF/ELSEIF arms, optional ELSE, and END IF/ENDIF, including nesting. Only the first matching arm executes.
- Bare `do` / END DO or ENDDO supports named/unnamed EXIT/CYCLE and mixed counted-loop nesting under the shared execution budget. See [docs/BARE-DO.md](docs/BARE-DO.md).
- Block `do while (condition)` supports scalar default LOGICAL conditions, fresh header evaluation after each iteration/CYCLE, named transfers and counted/bare/SELECT CASE nesting under the existing shared budget. See [docs/DO-WHILE.md](docs/DO-WHILE.md) for retained restrictions.
- Counted `do integer_variable = start, end [, step]` / END DO or ENDDO supports INTEGER(4/8) control, named loops, and named/unnamed EXIT/CYCLE. Bounds and step are evaluated once, with checked narrowing and terminal increment overflow. Zero-trip, descending and nested loops preserve correct final values and transfer cleanup. See [docs/CONTROL-FLOW.md](docs/CONTROL-FLOW.md).

- OPTIONAL scalar and rank-one/rank-two INTEGER(4/8), REAL(4/8), LOGICAL and default CHARACTER dummies support omission, keyword association, PRESENT, direct absent forwarding, all subroutine intents, generics, ELEMENTAL lifting and supported type-bound calls. Supported numeric, LOGICAL and CHARACTER allocatable array forms compose with OPTIONAL. Absent-value reads/writes and forwarding to required dummies fail at runtime. See [docs/OPTIONAL-ARGUMENTS.md](docs/OPTIONAL-ARGUMENTS.md).
- Nonoptional explicit-shape dummy arrays of rank one through three support bounded scalar-INTEGER entry-time bounds, same-rank element-order prefix association, larger-actual tail preservation and supported section copyback. Local automatic arrays/results can inquire about their frozen shapes. See [docs/EXPLICIT-DUMMY-BOUNDS.md](docs/EXPLICIT-DUMMY-BOUNDS.md).
- Named module-defined unary and binary operators accept supported intrinsic or derived operands, exact type/kind/rank overloads, and ELEMENTAL array lifting. PUBLIC/PRIVATE and scoped USE ONLY apply. Named defined binary operators have lower precedence than intrinsic operators; named defined unary operators bind more tightly. Existing intrinsic-symbol overloads retain their intrinsic precedence and derived-operand restrictions. Operator names are limited to 1–14 letters. See [docs/DEFINED-OPERATORS.md](docs/DEFINED-OPERATORS.md).
- Module-to-module imports preserve scope isolation and support original chained PARAMETER declarations. See [docs/MODULE-USE.md](docs/MODULE-USE.md).

The syntax recognizer reserves its statement and intrinsic names as identifiers, including PROGRAM/END, declaration and access keywords, module/procedure keywords, IF/DO/PRINT/CALL/RETURN/ERROR/STOP, and the earlier elemental/inquiry intrinsic names plus RANDOM_NUMBER. The array-intrinsic names and INDEX/LEN_TRIM/ADJUSTL/ADJUSTR may be shadowed by explicit declarations or user procedures, preserving existing source names such as SUM and INDEX. Fortran itself does **not** reserve these names. This is a documented subset restriction, not a language claim.

### Explicitly outside the subset

IMPURE prefixes on non-elemental procedures, writable function dummies, rank-four and higher arrays, vector subscripts outside the documented read-only rank-one CHARACTER/INTEGER/REAL and numeric rank-two row/rank-three single-vector gather subsets, nonempty numeric/logical typed and untyped empty array constructors, explicitly typed constructor indices, standalone DIMENSION statements and combined attribute/entity-shape declarations, assumed shapes outside dummy arguments and deferred shapes outside allocatable and bounded pointer declarations, OPTIONAL explicit-shape and assumed-size dummy arrays, variable bounds outside the documented automatic-array/explicit-dummy subsets, SIZE KIND and assumed-rank array inquiries, external procedures, separately compiled modules, mutable main-program host-associated variables, nonintrinsic module USE renaming, imported-name re-export and nonintrinsic USE inside procedures, derived array procedure results, OPTIONAL derived dummies, standalone OPTIONAL statements, writable function dummies, recursion without explicit RECURSIVE, RECURSIVE ELEMENTAL, ordinary function external I/O, SAVE outside the documented initialized intrinsic local-scalar and main-object subsets, inheritance, unlimited polymorphism, CLASS locals/results, named PASS/NOPASS, binding-generic overloads, arrays of derived values, nested/array components, nondefault-kind or nonconstant-length CHARACTER components, defined READ/unformatted I/O, DT tags/parameter lists, pointers outside the documented rank-one numeric subset, allocation outside the documented numeric/LOGICAL/CHARACTER rank-one/two/three subset, scalar numeric/LOGICAL allocatables, substrings of array-section bases/function results, writable substring actuals and value-dependent array constructor item lengths outside the descriptor-known subset, complex numbers, INTEGER kinds other than 4/8 and nondefault LOGICAL kinds, REAL kinds other than 4/8, other REAL kind-selector expression forms, legacy PARAMETER and standalone SAVE statements, unlisted declaration attributes, implicit variable typing, continued character literals or split lexical tokens, labels/GOTO, named non-DO constructs, DO CONCURRENT, BLOCK, READ outside the documented bounded internal and explicitly bound external subsets, external WRITE outside the documented stdout-only controls/units or registered defined-output callbacks, and file I/O, preprocessing, multiple main programs, and every unlisted statement/intrinsic/operator. Legal unsupported programs fail explicitly rather than being approximated.

## Execution semantics and limits

Constant declaration initializers and constant array bounds are checked by the same bounded
checked evaluator during compilation; invalid constants are rejected by
`--check`. PARAMETER values are converted to their declared types and stored separately
from mutable variables; their initializer trees and cached values are independently
cross-checked by the frontend adapter. Self/forward references and references to
ordinary variables are rejected as constant expressions. Each dimension extent is `max(upper - lower + 1, 0)`, computed in int64 after
checking both bounds against the supported INTEGER range. Each extent must fit the supported INTEGER range. A rank-two array's total is the product of its dimension extents, checked before allocation. At most 1,000,000 array
elements may be declared in total; runtime frame storage and a call’s array actuals each have the same element limit. Storage is heap-allocated per active execution frame.
The single named constant `max_array_elements` in `src/fi_ir.f90` controls these
array limits, including array-valued results and constructor/call temporaries.
Change that constant and rebuild to choose a different cap. The separate PRINT,
source-size, CHARACTER and work limits do not change. See
[configuration, memory costs and boundary tests](docs/ARRAY-LIMITS.md).
Source bytes, tokens and whole-source metadata have separate shared, build-time constants in
`src/fi_limits.f90`. See [source capacity and boundary tests](docs/SOURCE-LIMITS.md)
and [metadata capacity and heap storage](docs/METADATA-LIMITS.md).
Each element has its own initialization flag. All element reads and writes check
bounds at runtime, including empty arrays and statically evident bad indices;
`--check` accepts well-typed out-of-bounds accesses because it does not execute them.
An element assignment evaluates its value and index before changing any element.
A whole-array or section assignment computes and converts every result into a temporary
before changing the target, so `a = a + a(1)` uses the old `a(1)` for all elements.
Scalar expansion evaluates its scalar once, even for an empty target. Empty
array-valued expressions evaluate no elements; scalar data subexpressions inside them
are not evaluated. Section triplets are evaluated and validated even for empty
sections, once per expression occurrence per statement. A zero stride is an error.
Only selected indices must be in bounds; an unused endpoint or empty triplet
may lie outside the declared array. Target sections and RHS shapes are resolved
before any data changes; overlapping assignments always use the old data. This is the prototype's deterministic safety policy, not a
promise about optional expression evaluation by every Fortran compiler.
Array reductions/products validate operand shape and runtime DIM, preserve empty-result identities, and charge each loop iteration to the shared work budget. MASK skips unselected ARRAY values; scalar MASK is evaluated for a scalar identity result but not an empty output vector. Product/addition intermediates are checked for overflow/non-finite values. Intrinsic array results are capped at 1,000,000 elements, even when inferred from empty operands. See [array-intrinsic details](docs/ARRAY-INTRINSICS.md).
Declarations with explicit initializers define every selected element before execution. No implicit initialization occurs otherwise. See `examples/whole_arrays.f90`,
`examples/array_elements.f90` and `docs/ARRAYS.md`.

Each ELEMENTAL array-call element uses a fresh scalar invocation. Shapes and section descriptors are validated before evaluating any element, including for zero-sized results. Empty calls execute no function bodies and do not read scalar data actuals. Every executed element shares the same work budget as its caller; assignment still commits only after all results are ready. Elemental subroutines freeze whole-reference bindings and defer writable copy-back until all elements succeed. Impure array function expressions are materialized once per expression occurrence per executed statement, preserving ordered side effects when reductions or products revisit values.

RANDOM_NUMBER shares explicit RNG state across nested calls, resets it for each top-level execution and stages an entire HARVEST before committing. Failed calls preserve the target and RNG state, except that earlier external PRINT records cannot be rolled back. Empty harvests consume no draws. RNG output is not a compiler-sequence compatibility claim or a cryptographic source.

Each procedure invocation creates fresh storage for its arguments, unsaved locals and (for functions) RESULT. Caller bindings freeze writable scalar/element/section destinations before the call. Type-matched values and definition flags enter dummy slots, and writable slots return their values and flags to the caller. INTENT(OUT) discards incoming definition state, including for each selected array element. Overlapping direct actual bindings are rejected if either dummy is writable; disjoint sections and read-only aliases are allowed. IN array expressions use temporary values. See [argument association details](docs/ARGUMENT-ASSOCIATION.md). Module variables share storage across frames. Internal procedures share supported captured variables from the exact active defining host, including during recursive host re-entry; mutable main-program host variables remain excluded. A direct module, SAVE or captured-host actual may not also be accessed through the callee’s transitive host/USE associations. All nested calls share the same execution budget; direct and indirect recursive cycles require explicit RECURSIVE on every participating procedure, even in unused functions. The 65th active procedure frame fails safely at runtime. A function result must be defined on the executed path; supported derived-component defaults establish those component values on entry. Ordinary functions may call validation subroutines but cannot perform external I/O, directly or transitively. Internal formatted WRITE to a local CHARACTER buffer and the documented internal numeric/CHARACTER list-directed READ subset are supported. Explicitly IMPURE ELEMENTAL functions may do both, with recursive PRINT rejected at execution time; impure subroutines may print. Initialized intrinsic scalar procedure locals retain one shared value for the whole execution, including recursive activations; each independent execution resets them. Both implicit SAVE and the explicit declaration attribute are supported. Ordinary-function shared-storage/I/O restrictions and PURE/SIMPLE restrictions still apply. See [saved local state](docs/SAVED-LOCALS.md).

The runtime uses signed 32-bit default INTEGER and signed 64-bit INTEGER(kind=8) semantics, plus IEEE-like real32 and real64 arithmetic on the verified toolchain. Real values carry their kind; real32 operations round at each operation and conversion rather than silently gaining real64 precision. Integer values carry their kind; checked 64-bit operations detect overflow before executing the native operation, and assignments/conversions check the destination range. It checks integer arithmetic and conversion ranges, division by zero, non-finite real results, invalid power domains, uninitialized reads, a zero DO step, mutation/reuse of an active DO variable, and DO terminal-value overflow. Real underflow may round to zero normally. Logical operands are evaluated eagerly; no short-circuit guarantee is made by Fortran or this prototype.

The default work budget is 1,000,000 instruction/expression evaluations, overridable with `--max-steps`. On exhaustion, the CLI reports the actual configured budget and suggests `--max-steps N`; increasing it allows more work but does not guarantee termination. The reusable runtime API diagnostic stays unchanged. Limits also cover 262,144 tokens (including a final synthetic separator and EOF), 8,192 symbols, 10,000 expression nodes, 4,000 instructions, 64 nested source blocks/recursive parse levels, 256 adapter tree depth, 512 evaluation depth, 64 output items, 65,536 expanded output values, 16 MiB of collected CHARACTER output data, 65,536 staged literal-format characters, 16 MiB staged list-directed characters, 16 procedure arguments, 16 modules, 1,024 procedures, 256 generic interfaces, 1,024 PUBLIC names and 1,024 PRIVATE names per module, 1,024 names per USE ONLY list, and 64 active procedure frames. Exceeding a limit is an explicit error. This is not an OS-level isolation or hostile-input security guarantee; FortFront is experimental and its parser runs in-process.

PRINT uses deterministic space-separated values, `T`/`F`, and nine significant decimal digits for real32 and seventeen for real64. Formatted PRINT uses the requested supported descriptors. Adjacent character items are concatenated, as in list-directed output. It does **not** reproduce a compiler's exact list-directed spacing, line wrapping, or choice of exponent formatting. Differential tests compare values rather than byte-for-byte compiler formatting. A PRINT statement evaluates every item before writing that record. Output from earlier successful statements can remain if a later runtime error occurs.

## Architecture and FortFront integration

1. `fi_parser`: a bounded independent syntax recognizer that consumes every source token, enforces the subset, typing and scalar/rank-one/rank-two conformability, and builds a private typed representation. This catches invalid syntax even if FortFront silently repairs it.
2. `fi_frontend`: compiles the original source through FortFront in STANDARD/STRICT mode and checks declarations, kinds, ranks, bindings, statements and expression trees against that representation. Disagreement is a compilation error. This is a real cross-check of the parsed AST, not a `success()`-only gate.
3. `fi_ir`: frontend-independent values, expression trees, symbols and flattened control-flow instructions. No borrowed arena pointers reach the runtime.
4. `fi_runtime`: evaluates the private representation with explicit arithmetic, initialization and work-limit checks.
5. `fi_driver` / `app/main.f90`: reusable compile entry point and small CLI.

The adapter currently uses FortFront's exposed Fortran AST node types where its higher-level queries do not expose enough structural information. This dependency is intentional, pinned, isolated in one module, and covered by adapter regressions; it is not a stable external ABI.

The vendored source comes from [FortFront commit 9a5896a1fce32c394fd02dd1da1bd261ea7a646f](https://github.com/lazy-fortran/fortfront/tree/9a5896a1fce32c394fd02dd1da1bd261ea7a646f). Targeted producer-side corrections are retained as patches, not silently represented as upstream behavior. See [docs/FRONTEND.md](docs/FRONTEND.md) and [vendor/patches](vendor/patches). The original evaluation checkout is unchanged. The malformed-expression parser issue is contained by the strict recognizer and AST agreement checks; it is not claimed to be fixed across the upstream parser.

FortFront has process-global semantic state. Concurrent compilation calls within one process remain unsupported; use separate processes. The local mode fix addresses a tested sequential metadata leak, not all possible global-state issues.

## Tests and provenance

`fpm test` runs native Fortran frontend and runtime contract regressions. `scripts/verify.py` (or the Bash wrapper `scripts/verify.sh`) also runs the independent source corpus against both the interpreter and GNU Fortran with `-std=f2018 -pedantic-errors -fcheck=all`. The suite contains independently specified stdout expectations and negatives; invalid/unsupported sources must not emit program output. Runtime-policy cases are tested against the interpreter's safety contract, not treated as compiler conformance proofs.

The 0.27 additions have focused suites for [OPTIONAL CHARACTER](tests/optional_character),
[OPTIONAL numeric/logical arrays](tests/optional_numeric_arrays),
[scalar CHARACTER substrings](tests/character_substrings),
[INDEX/LEN_TRIM/ADJUSTL/ADJUSTR](tests/character_intrinsics), and
[combined source-preserving cases](tests/release027_integration).
Original utility procedure bodies and new wrappers are identified separately.
The exact full utility file still does not execute: its first diagnostic is
explicit-shape dummy bounds in fold_bounds at line 6504, column 34, after passing
the earlier OPTIONAL, TARGET and bounded POINTER declaration gates.

The 0.26 additions have focused suites for [allocatable CHARACTER](tests/allocatable_character),
[FORALL](tests/forall), [rounding and LOG10](tests/rounding_intrinsics), and
[cross-feature original-body composition](tests/release026_integration).
Retained original procedure bodies and new synthetic drivers are identified separately.
OPTIONAL CHARACTER scalars and rank-one/rank-two arrays, including supported
allocatable arrays, are documented in [OPTIONAL-ARGUMENTS.md](docs/OPTIONAL-ARGUMENTS.md)
and verified by [tests/optional_character](tests/optional_character).
The exact full-source boundary is recorded above and in [docs/VERIFICATION.md](docs/VERIFICATION.md).

The 0.24 additions have focused suites in [tests/allocatables](tests/allocatables),
[tests/allocatable_assignment](tests/allocatable_assignment),
[tests/allocatable_dummies](tests/allocatable_dummies), [tests/formatted_arrays](tests/formatted_arrays),
and [combined allocatable/output tests](tests/allocatable_output). They include the complete
unchanged upstream demo_dot_product program, original alloc_sub utility procedure bodies
in a new driver, and independent synthetic fixtures. Those are distinct source artifacts.
See [docs/ALLOCATABLES.md](docs/ALLOCATABLES.md) and [docs/FORMATTED-ARRAYS.md](docs/FORMATTED-ARRAYS.md).

The 0.23 additions have focused suites in [tests/mutable_modules](tests/mutable_modules),
[tests/location_intrinsics](tests/location_intrinsics), expanded [RESHAPE initializer tests](tests/reshape),
and [combined original IMINLOC/VECTOR integration](tests/release_integration).
Shared mutable state includes defined formatted-output callbacks and numeric allocatable module arrays. See [docs/ALLOCATABLES.md](docs/ALLOCATABLES.md) for bounded allocation syntax, lifetime and remaining limitations.
The [verification report](docs/VERIFICATION.md) records exact coverage and remaining boundaries.

The 0.22 additions have focused suites in [tests/metadata_limits](tests/metadata_limits),
[tests/count_bounds](tests/count_bounds), [tests/pack_intrinsic](tests/pack_intrinsic),
[tests/reshape](tests/reshape), [tests/count_pack_integration](tests/count_pack_integration),
and [the combined original-body replay](tests/count_pack_reshape_integration).
These execute original true_pos_func, positive_int_vec, vector and matrix_from_vec bodies while
retaining explicit full-file boundaries. The untouched original utilities file
now passes numeric allocatable module declarations and inferred-length CHARACTER
PARAMETERs. Its current first rejection is explicit-shape dummy bounds in fold_bounds at line 6504, column 34. The full original still does not run. See [docs/METADATA-LIMITS.md](docs/METADATA-LIMITS.md).

The 0.21 additions have focused suites in [tests/automatic_arrays](tests/automatic_arrays),
[tests/array_results](tests/array_results), and [tests/hyperbolic_intrinsics](tests/hyperbolic_intrinsics).
Exact original utility bodies include normalize, vector/matrix differences, growing means,
bin counts and sech. Full utilities-module support is not claimed.

The 0.20 additions have focused suites in [tests/defined_operators](tests/defined_operators),
[tests/optional_arguments](tests/optional_arguments), [tests/control_flow](tests/control_flow),
[tests/logical_intrinsics](tests/logical_intrinsics), and [tests/module_use](tests/module_use).
The combined retained-utility modules and new driver are in
[tests/release_integration/utilities_combined_020.f90](tests/release_integration/utilities_combined_020.f90).

The 0.17 additions have focused suites in [tests/select_case](tests/select_case),
[tests/derived_types](tests/derived_types), [tests/derived_date_independent](tests/derived_date_independent),
[tests/derived_select_integration](tests/derived_select_integration),
[tests/integer_kinds_independent](tests/integer_kinds_independent),
[tests/array_expression_arguments](tests/array_expression_arguments),
[tests/logical_initializers](tests/logical_initializers), and [tests/array_limits](tests/array_limits).
The exact requested programs are `examples/month_date.f90`, `examples/select_case.f90`,
`examples/mean_random_power.f90`, and `examples/random_summary_100000.f90`.
The 0.19 source/token boundaries are checked in [tests/source_limits](tests/source_limits).
The supplied `xutilities.f90` is preserved and broken into reviewable fragments and
focused runnable/rejected examples. See [docs/UTILITIES.md](docs/UTILITIES.md)
for the decomposition, the tested smaller programs and remaining full-file boundaries.
Raising the byte cap does not make the entire utilities library supported.

The 0.18 additions are checked in [tests/character_arrays](tests/character_arrays),
[tests/generic_interfaces](tests/generic_interfaces), [tests/class_type_bound](tests/class_type_bound),
and [tests/release_integration](tests/release_integration). Their exact requested
examples are `examples/character_arrays.f90`, `examples/generic_twice.f90` and
`examples/month_date_class.f90`. See their linked feature contracts for boundaries.

KIND inquiries, constructors/initialization and RANDOM_NUMBER are independently tested in [tests/mean_programs_independent](tests/mean_programs_independent). Both requested mean programs are included unchanged in `examples/mean_constructor.f90` and `examples/mean_random.f90`.

ELEMENTAL subroutine association, writable definition flags, IMPURE function/subroutine order and safe failures are independently tested in [tests/elemental_subroutines_independent](tests/elemental_subroutines_independent).
Pure ELEMENTAL calls, scalar expansion, rank-one/rank-two shapes, sections and safe failures are independently tested in [tests/elemental_functions_independent](tests/elemental_functions_independent).
Keyword association, all permutations, writable arguments, invalid calls and safe failures are independently tested in [tests/keyword_arguments_independent](tests/keyword_arguments_independent).
Array-intrinsic reductions/products, empty identities, DIM/MASK, sections, mixed kinds and safe failures are independently tested in [tests/array_intrinsics_independent](tests/array_intrinsics_independent).
Whole-array regressions and independently specified oracles are in [tests/whole_arrays](tests/whole_arrays).
Module function and independent GNU-oracle cases are in [tests/module_functions](tests/module_functions).
Rank-two section combinations, strides, inquiries, assignment and dummy association are tested in [tests/rank_two_sections](tests/rank_two_sections). See [docs/RANK-TWO-SECTIONS.md](docs/RANK-TWO-SECTIONS.md) and `examples/matrix_sections.f90`.
Rank-two layout, dimension conformance, zero extents, matrix procedures and independent GNU-oracle cases are in [tests/rank_two](tests/rank_two). See [docs/RANK-TWO-ARRAYS.md](docs/RANK-TWO-ARRAYS.md).
Argument association, scalar OUT/INOUT, assumed-shape arrays and independent GNU-oracle cases are in [tests/argument_association](tests/argument_association).
Black-Scholes, real64, subroutine, formatted PRINT and independent GNU-oracle cases are in [tests/numerical_procedures](tests/numerical_procedures).
Section triplet, overlap, dynamic-shape and runtime-policy cases are in [tests/sections](tests/sections).
Array details and limitations are in [docs/ARRAYS.md](docs/ARRAYS.md).
Program-form and PARAMETER regressions are in [tests/program_forms/README.md](tests/program_forms/README.md).
The earlier requested examples print `32` and `55`; both are included unchanged in
`examples/implicit_main_power.f90` and `examples/parameter_sum.f90`.

See [docs/VERIFICATION.md](docs/VERIFICATION.md) for exact results from the delivered source. Passing these selected tests is not an estimate of full-language conformance. No upstream-wide test-suite pass or compiler-backend implementation is claimed.

The prototype and vendored FortFront code are MIT licensed. See [LICENSE](LICENSE), [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md), and the retained [FortFront license](vendor/fortfront/LICENSE).

Historical parser boundary: a CHARACTER literal containing only `[` in the older formatted PRINT repro was corrected in 0.43. The historical release composition evidence and the separate GNU deferred-CHARACTER section-copyback discrepancy remain retained; current punctuation-literal tests require acceptance.

LOGICAL allocatable arrays use the same bounded rank-one/two/three descriptor model;
see [LOGICAL-ALLOCATABLES.md](docs/LOGICAL-ALLOCATABLES.md) for independently checked
original utility slices, lifecycle, assignment, argument and result behavior.

Bounded immediate CHARACTER literal substrings are documented in
[docs/LITERAL-SUBSTRINGS.md](docs/LITERAL-SUBSTRINGS.md).

Quoted CHARACTER operator spellings remain data; see
[docs/QUOTED-OPERATORS.md](docs/QUOTED-OPERATORS.md).

Contextual `procedure` entity and dummy names are documented in
[docs/PROCEDURE-IDENTIFIERS.md](docs/PROCEDURE-IDENTIFIERS.md).

Contextual CHAR data/procedure names and preserved unshadowed intrinsic behavior
are described in [CHAR-IDENTIFIERS.md](docs/CHAR-IDENTIFIERS.md). Focused original
`positions_char_string` tests retain its two original helper bodies byte-for-byte.

- Bounded numeric gathering supports rank-one INTEGER(4/8) and REAL(4/8) bases, `matrix(rows,:)` for rank two, and one vector on any rank-three axis with bare colons elsewhere. Index order, duplicates and snapshot-before-assignment are preserved. [Numeric rank-one gathers](docs/NUMERIC-VECTOR-GATHER.md) admit bare actuals only to ordinary same-type/kind assumed-shape `INTENT(IN)` dummies, with conservative whole-base alias checks. [CHARACTER gathering](docs/CHARACTER-GATHER.md) retains its separate descriptor/string-payload limits. This is not scatter or general vector subscripting.

- Bounded REAL(4/8) SPACING and NEAREST, including mixed-kind directions and rank0–3 elemental arrays; see docs/SPACING-NEAREST.md.

- GNU extension `ISNAN(X)` supports elemental REAL(4/8) finite inputs and default LOGICAL results. The finite-value safety policy remains unchanged. See [docs/ISNAN.md](docs/ISNAN.md) for explicit nonstandard status, limitations and helper-free original quick_sort evidence.

- `ERFC_SCALED(X)` supports elemental REAL(4/8) with guarded finite negative endpoints and stable positive subnormal tails. See [docs/ERFC-SCALED.md](docs/ERFC-SCALED.md) for mathematical accuracy evidence and separately recorded GNU-runtime discrepancies.

### Two-argument pointer association inquiry

Bounded `ASSOCIATED(POINTER, TARGET)` compares exact ordered storage identity for
rank-one INTEGER/REAL kind 4/8 views, including sections of rank-two targets. It
preserves undefined-state, lifetime, zero-size and resource checks without reading
pointee values. See [the supported subset and oracle exceptions](docs/ASSOCIATED-TARGET.md).

Bounded standard `ERF` and elemental `BESSEL_J0/J1/JN/Y0/Y1/YN` support is
specified in [ERF/Bessel](docs/ERF-BESSEL.md), including REAL4/8 domains, exact
original demonstrations and independent accuracy evidence. Singular Y0(0) remains
an explicit runtime rejection, not a successful original-example execution.

### REAL exponent-model inquiries

`MINEXPONENT(X)` and `MAXEXPONENT(X)` return default INTEGER scalar model limits
for REAL kind 4/8 without reading whole undefined, unallocated or absent arguments.
The unchanged M_intrinsics demo_minexponent executes. See
[the supported inquiry subset and original-program boundaries](docs/EXPONENT-MODEL-INQUIRIES.md).

## Main-program SAVE attribute extension

Explicit SAVE on initialized main-program intrinsic scalars and fixed-shape
rank-one/two/three arrays now uses the existing execution-long root storage.
The complete unchanged M_intrinsics demo_minloc executes. Procedure-array SAVE
and storage limits are unchanged. See [MAIN-PROGRAM-SAVE.md](docs/MAIN-PROGRAM-SAVE.md).

### Bounded unlimited formats and G0

Literal formats accept one final outer unlimited group `*(...)` and bare `G0`
for intrinsic scalar items, including expanded arrays. Existing value, traversal
and staged-output caps remain unchanged. Both complete original M_intrinsics
`demo_erfc` and `demo_log10` execute without source adaptation. See
[the bounded format contract and evidence](docs/UNLIMITED-FORMATS.md).

## Multi-object allocation extension

Bounded ALLOCATE/DEALLOCATE lists support up to 64 whole allocatable arrays,
with checked left-to-right effects and one optional STAT. Earlier successes are
preserved when a later object fails. Existing limits remain unchanged; see
[MULTI-OBJECT-ALLOCATION.md](docs/MULTI-OBJECT-ALLOCATION.md).

The complete supplied normal-mixture EM program and its minimal ACOS variant
are retained in [the normal-mixture validation suite](docs/NORMAL-MIXTURE.md).
Full runs use the existing explicit step-budget option; the default limit is
unchanged.

### Named constant output formats

PRINT and supported WRITE forms accept visible scalar CHARACTER PARAMETER names
as formats, with source declaration/initializer validation and unchanged output
bounds. This composes with ASIN to execute unchanged M_intrinsics demo_asin.
See [the named-format contract](docs/NAMED-FORMATS.md).

## Scalar allocatable CHARACTER extension

Default-kind scalar CHARACTER now supports checked allocation status, whole-variable length reallocation, procedure argument transfer and fresh local lifetimes. The unchanged M_intrinsics demo_adjustl executes against GNU. See [the supported subset and evidence](docs/SCALAR-ALLOCATABLE-CHARACTER.md).

## Finite degree intrinsic extension

ACOSD, ASIND, SIND and COSD support finite REAL4/8 scalars and arrays through rank three, with checked inverse domains and unchanged resource limits. Three complete unchanged M_intrinsics demos passed in the isolated degree-intrinsic milestone; its later T20 prerequisite is supported by the positioning extension. See [the bounded contract and oracle caveat](docs/DEGREE-TRIGONOMETRY.md).

## ASCII lexical comparison extension

LGE, LGT, LLE and LLT compare default CHARACTER scalars and conforming arrays through rank three using ASCII ordering and blank padding. All four complete unchanged M_intrinsics demos have byte-exact GNU output agreement. Non-ASCII data and wider CHARACTER kinds are outside the bounded contract. See [lexical comparisons](docs/LEXICAL-COMPARISONS.md).

## Default-CHARACTER MIN/MAX extension

MIN/MAX now support default CHARACTER scalars and conforming arrays through rank three, preserving significant blanks and padding results to the longest argument length. The unchanged demo_max passes its independent full-output oracle. GNU 14.2's constant-array length defect is explicitly recorded, not counted as GNU execution agreement. See [CHARACTER MIN/MAX](docs/CHARACTER-MINMAX.md) for the contract, optional constructor-composition profile and verification evidence.

Bounded array-constructor implied-DO details and exact original utility coverage: [docs/CONSTRUCTOR-IMPLIED-DO.md](docs/CONSTRUCTOR-IMPLIED-DO.md).

### External list input and bounded BACKSPACE

The explicit `--input UNIT=PATH` mechanism now supports bounded list-directed
INTEGER/REAL/default-CHARACTER transfer and BACKSPACE over the supplied records.
No source-requested file access is added. Exact original `read_alloc_char`
closures are covered. The numeric extension advances the authorized
working utility to unsupported INQUIRE at 2992:1; full-library support is not claimed. See [EXTERNAL-READ](docs/EXTERNAL-READ.md)
and `tests/external_list_read` for the supported contract and retained evidence.

## EOSHIFT end-off array shifts

EOSHIFT now supports rank-one/rank-two intrinsic arrays with scalar or vector
SHIFT/BOUNDARY, optional DIM, exact default boundary values and safe large signed
shifts. The complete unchanged M_intrinsics demo_eoshift passes byte-exact against
strict GNU14.2. See [EOSHIFT](docs/EOSHIFT.md) for the bounded contract, independent
checks and the separately recorded machine-minimum GNU runtime limitation.

## Descriptor-length CHARACTER constructors

Untyped constructors now obtain matching lengths from supported runtime
CHARACTER descriptors, including nested implied-DOs and empty results. Exact
original `repeat_char` and `repeat_char_vec` closures execute against GNU;
value-dependent TRIM, dynamic substrings and function-result lengths remain
outside this bounded extension. See [the contract and empty-length oracle
caveats](docs/DYNAMIC-CHARACTER-CONSTRUCTORS.md).

## Version 0.49 contracts

The [release summary](docs/RELEASE-0.49.md) links the current grouped-default,
CHARACTER-component, runtime-unit, generic REPEAT, slash and LEADZ contracts.
The unchanged BTEST demo now passes its complete 24-record GNU comparison in the
integrated slash profile. Earlier feature-only observations remain historical;
full release results belong to [verification](docs/VERIFICATION.md).

## Version 0.50 contracts

The [release scope](docs/RELEASE-0.50.md) and [element-file contract](docs/INTERNAL_WRITE_ELEMENT.md) describe the bounded additions without implying full utility execution. Measured whole-release results belong to [verification](docs/VERIFICATION.md), not these focused feature summaries.

`MASKL`/`MASKR` accept INTEGER(4/8) counts but default to INTEGER(4), unless constant KIND=4/8 is supplied. `SHIFTR` retains I's kind; SHIFT may independently have kind4/8. Scalar expansion and conforming rank-one/two/three arrays are supported, with checked counts and unchanged limits. See [INTEGER masks](docs/INTEGER-MASKS.md). The unchanged MASKL/MASKR demos pass their focused byte-exact profiles; the complete SHIFTR demo still requires unsupported ISO small kinds/BOZ and is not a full-original gain.

### Rank-three numeric vector gathering

Bounded single-vector gathering now supports any one tensor axis, preserving
column-major values, snapshots and existing limits. See
[the focused contracts](tests/rank_three_vectors/README.md) for exact original
utility closures, public-IR safety evidence and retained boundaries.

## Rank-one CHARACTER gathering and read-only bare actuals

`strings(indices)` accepts a named non-POINTER rank-one default CHARACTER array
and a rank-one INTEGER(4/8) vector. Fixed, assumed and deferred descriptors,
empty results, duplicate order and snapshot-before-reallocation are bounded as
specified in [CHARACTER-GATHER](docs/CHARACTER-GATHER.md). The per-frame resident
gather-string cap is not a whole-process heap guarantee.

A bare gather may associate with an ordinary non-TARGET, non-POINTER,
non-ALLOCATABLE assumed-shape `INTENT(IN)` dummy. It retains a conservative
whole-base alias reservation; same-base writable siblings remain rejected even
for disjoint or empty selections. Extra parentheses instead denote an independent
snapshot. Adapter validation checks that marker against the producer's source
tokens, including the distinct function closing-token location contract.

Direct derived-component selectors remain an explicit CHARACTER-only metadata
limitation; assign the component to an ordinary scalar first. Dynamic-length
untyped gather constructors, scatter and CHARACTER rank-two/three gathers remain
outside this checkpoint. Numeric rank-one gathering has its separate contract below. Original utility closures are
focused evidence, not full-module execution. Whole-release results and any
standalone intrinsic survey are reported separately in [VERIFICATION](docs/VERIFICATION.md).

### Numeric rank-one vector subscripts

See [bounded numeric gathering and validation](docs/NUMERIC-VECTOR-GATHER.md) for INTEGER/REAL vector subscripts, read-only actual association and retained utility/effect boundaries.

### TRAILZ and ISO availability scope

TRAILZ accepts supported INTEGER(4/8) scalar and elemental array operands and returns default INTEGER, including 32/64 for zero. ISO availability imports report INT8=-1, INT16=-1 and INTEGER_KINDS=[4,8] for this interpreter, not the host compiler. They do not provide small-kind storage, literals or arithmetic. Imported INTEGER_KINDS elements and sections retain array binding across supported aliases and host association; see [the bounded contract](docs/TRAILZ-ISO-INTEGER-AVAILABILITY.md). No new release verification or survey counts are asserted here.
