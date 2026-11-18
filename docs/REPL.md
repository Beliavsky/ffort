# Source-buffer REPL with bounded retained sessions (development preview)

On a terminal, run `ffort.exe` without a source filename to enter the REPL.
FPM also builds the common CLI as `fortfront-interpreter`. The existing Windows
executable naming workflow is unchanged.

`--repl` (alias `--interactive`) forces a session when stdin is a pipe. Without
a filename or either flag, nonterminal stdin is complete batch source, not an
interactive transcript. `--nologo` hides the banner; `--prompt TEXT` changes the
prompt (up to 128 printable characters, including an empty prompt).
`--max-steps N` bounds execution. `--defer-check` suppresses immediate assignment/PRINT
execution and preserves the prior deferred source-buffer behavior; bare queries and
explicit `.run` still execute on request. This option requires REPL mode. REPL mode rejects a filename, `--check`, and
registered `--input` bindings; those remain batch options.

## Buffer and commands

Enter standard Fortran declarations and statements for one program body. The
stored body is wrapped in `program repl_session`, `implicit none`, and
`end program repl_session`. It is not rewritten into assignments or query
history. Declarations precede executable statements.

- `.` or `.run`: explicitly reset and execute the complete buffered program once.
- `.list`: number editable body lines; show the fixed wrapper without editable numbers.
- `.list -n`: display exact plain wrapped source.
- `.del`, `.ins`, `.rep`: transactional body-line edits. Executed-source edits require explicit successful `.run` or `.clear` before queries resume; see [editor rules](REPL-EDITOR.md).
- `.clear`: discard the body, values, execution frontier, taint and last error.
- `.help`: describe commands and limits.
- `.vars [names]`: execute admitted pending statements once, then inspect all or selected retained values; undefined scalars show `<undefined>`.
- `.info [names]`: type, kind, rank and CHARACTER length metadata plus the same bounded value display.
- `.shapes [names]` / `.sizes [names]`: array extents / total element counts. Without names, list only arrays; an explicitly named scalar prints `name: scalar`.
- `.save [file]`: write standard source, never overwrite an existing file. Without a name choose the first unused `main.f90`, `main1.f90`, etc.
- `.load file`: read a source file saved by this REPL, reset values, and retain its body without executing it.
- `.quit`: autosave a nonempty body to an unused `main*.f90` and exit; failed save leaves the session open.
- `.quit!`: exit without saving.

Top-level assignments and PRINT execute immediately when the entire buffered
prefix compiles and is admitted to the bounded retained-session subset. Previously
executed effects are not replayed. Incomplete constructs and unsupported programs
remain buffered for explicit `.run`; this stage does not yet provide ofort's
immediate rejection of malformed source. Runtime errors taint the session and
require `.clear` or an explicit successful `.run`.
Incomplete constructs can be entered across lines and checked on `.run`.
EOF never runs or saves. Repeating `.run` deliberately repeats the full program's
effects from fresh state. A compile failure leaves the existing session intact;
a failed runtime execution is not retried implicitly. A successful run or query,
or `.clear`, clears the returned error status. Listing/help do not clear it.

## Persistent queries

A bare supported expression triggers the following bounded workflow:

1. Compile and frontend-verify the body and the body plus a temporary expression
   PRINT. Admit both to the retained-session subset before any pending effects.
2. Verify the prior declarations and complete expression/instruction prefix
   against the retained snapshot; execute only newly buffered instructions.
3. Evaluate the temporary query against retained values. Do not append the query
   to the source or commit it to the instruction frontier.

Repeated queries therefore do not repeat earlier output or advance the RNG.
Assignments and PRINT can execute pending instructions immediately; buffered random
calls execute once at the next admitted assignment, PRINT or query.

```text
> integer :: n
> n = 2
> print *, 'once'
once
> n*n
4
> n = n + 1
> n
3
> n
3
> .quit!
```

Persistent sessions allow directly local nonallocatable scalar INTEGER, REAL,
LOGICAL and fixed-length default CHARACTER, plus fixed explicit-shape rank-one
INTEGER(4/8), REAL(4/8) and LOGICAL(4) arrays. Array bounds must be admitted
constant integer expressions; the aggregate array limit is 100,000 elements.
Bound validation is limited to depth 32 and 100,000 total expression visits.
Retained arrays support scalar broadcast (including supported numeric scalar
conversions), element assignment/read, homogeneous whole-array copy, and
whole-array PRINT/query. Nonempty scalar-item constructors such as `[1,2,3]`
are admitted for INTEGER, REAL and LOGICAL, up to 256 items per constructor.
Array unary `+`, `-`, `.not.`, arithmetic `+`, `-`, `*`, `/`, numeric comparisons,
and logical operations support scalar expansion. New array operations require
matching operand type/kind and conforming array extents; mixed numeric kinds or
types are not silently promoted. Array-to-array assignment also requires the
same type/kind and extent, but lower bounds may differ. Self-reference such as
`a=a+1` evaluates a staged RHS before changing the target.

One-argument `SUM`, `PRODUCT`, `MINVAL`, `MAXVAL`, `ALL`, `ANY` and `COUNT` are
admitted on appropriate rank-one arrays, including in assignments and IF
conditions. Empty-array identities follow the ordinary interpreter. Undefined
array elements are not replaced with zeros; reads fail and taint the session.
New expressions are bounded to 100,000 elements each, 1,000,000 summed rank-one
expression extents and 100,000 argument edges per admitted program. Execution
step limits apply to constructor scanning, reduction traversal and shared DAGs.
The frontend's existing 132-column source limit still applies; the 4096-byte
REPL command limit does not relax it. Long constructors can be assembled with
continuation lines using the editor or saved-source loading. Each element has its own definedness flag. `.vars`
shows array bounds, defined count and at most the first 16 elements.

Complete forward IF blocks, nested IF/ELSE IF/ELSE, and single-line IF are
admitted. An incomplete block has no effects until its outer `END IF`/`ENDIF`
arrives. Complete counted DO, DO WHILE and bare DO blocks are admitted too.
Counted loops use scalar INTEGER variables, bounds and optional step; bounds
and step freeze at entry and the final index is retained. DO WHILE retests its
scalar LOGICAL condition on every iteration. Bare DO requires an EXIT or a
runtime step limit to terminate. Nested IF and loops are supported up to 64
active loop levels.

EXIT and CYCLE can target the innermost loop or an explicitly named enclosing
loop. Transfers unwind inner counted-loop controls, permitting their later
reuse. Loop construct names are case-insensitive and unique within the program;
END DO names must agree with their opening construct. Ordinary IF branches
cannot enter or escape a loop body. Only validated loop and transfer edges can
cross these boundaries. `END DO` and `ENDDO` are case-insensitive.

Only closed loops commit: step exhaustion, zero step, overflow or another runtime
error taints the session and cannot silently retry its partial output. Incomplete
loops remain buffered without effects. Repeated queries and `.vars` do not rerun
completed loops. Complete SELECT CASE blocks are retained too. Scalar INTEGER, LOGICAL and
CHARACTER selectors dispatch once, with value lists, open/closed INTEGER or
CHARACTER ranges, and one CASE DEFAULT in any position. No-match and empty
SELECT blocks continue normally. Use spaced `END SELECT`; compact `ENDSELECT`
is not supported by the source parser. Named SELECT constructs remain outside
this subset. Nested SELECT, IF and DO compose, including
EXIT/CYCLE to enclosing loops. Only closed whole SELECT blocks commit, and
ordinary branches cannot enter or cross arms. At most 64 nested SELECT blocks
and 64 alternatives per SELECT are admitted. Reversed ranges are empty.

INTEGER and LOGICAL CASE bounds must be literal/unary/binary constant expressions
(without variables or function calls), bounded to depth 32 and 100,000 aggregate
expression visits. CHARACTER nodes anywhere inside bound expressions are literals only, avoiding
large intermediate concatenations, including within logical comparisons. Literal
CHARACTER bytes counted on every constant-expression visit total at most 16 MiB. The program
is limited to 4096 evaluated endpoints and 100,000 interval comparisons. Overlap,
duplicate defaults, invalid ownership or a partial execution frontier is rejected
before any pending effects. CASE bounds are checked independently of the normal
source parser. Other unsupported constructs still require explicit `.run` and
do not establish resumable retained state.

Executable instructions also include assignment, advancing PRINT,
scalar `RANDOM_NUMBER` and no-argument `RANDOM_SEED`. No earlier instruction is
replayed when an admitted suffix or query is executed.

Scalar and rank-one expressions include supported unary/binary operations and seven unary
elemental intrinsics: `ABS` for INTEGER/REAL, and `SQRT`, `SIN`, `COS`, `EXP`, `LOG`,
`LOG10` for REAL. Each takes one scalar or rank-one argument of kind 4 or 8 and returns the
same type/kind/rank/extent. Nested calls, array assignment and reductions over
these elemental results are supported. Empty arrays stay empty; domain and
undefined-element errors are evaluated only when element values are needed.

`SIZE(array[,dim])`, `LBOUND(array[,dim])` and `UBOUND(array[,dim])` accept
admitted rank-one expressions. DIM is scalar INTEGER kind 4 or 8 and must
evaluate to 1; omitted DIM yields scalar SIZE or a one-element INTEGER(4) bounds
vector. With DIM, bounds results are INTEGER(4) scalars. Standard ARRAY= and DIM=
keywords may be reordered, including in bare queries; they are never appended
to the source. Top-level assignment `a(size(a))=value` remains source. KIND
arguments are excluded even when KIND=4.

Whole nonempty unparenthesized array variables preserve their declared bounds.
Parenthesized arrays and array expressions have lower bound 1 and upper bound
equal to extent. Empty rank-one arrays have SIZE=0 and bounds 1:0. These
inquiries inspect shape, not values: undefined elements, or a domain error in
a shape-only expression such as `size(sqrt(a))`, are not read/evaluated.
Definedness and RNG state remain unchanged. Invalid constant DIM may fail during
compilation without taint; invalid or undefined dynamic DIM fails at runtime
and taints the session. Pending admitted instructions still execute once on a
valid inquiry, under the same no-replay and edit gates.

Nested admitted calls are supported. Array sections, exponentiation, mixed-type/kind array operations, other array math
intrinsics such as `TAN(a)`, array RANDOM_NUMBER, CHARACTER arrays,
dynamic/allocatable arrays and user functions remain outside retained mode.
Typed, empty, nested, array-item and implied-DO constructors are excluded;
reduction MASK/DIM/KIND arguments are excluded.
Parameters, declaration initializers, SAVE, pointers, derived objects,
modules/procedures and external input are also excluded. Domain,
undefined-element and bounds errors use the normal runtime diagnostics and
taint policy.

The persistent-only aggregate CHARACTER budget is 16 MiB: declared scalar
CHARACTER lengths plus CHARACTER literal bytes and PRINT format bytes in the
admitted program. These admission limits do not change ordinary batch execution.

After successful retained execution, including a literal-only query, you may add
one fresh plain default-kind scalar using `integer :: name`, `real :: name` or
`logical :: name`. Case, horizontal whitespace and a trailing comment are
preserved. The declaration is hoisted after the existing specification region
and before executable source; `.list`, `.save` and later diagnostics show the
resulting one-line shift. It starts undefined without executing any old or
pending statement, consuming RNG state, or changing the execution frontier.
Existing scalar/array values and per-element definedness remain intact.

This narrow transaction requires a complete, healthy admitted source buffer.
It refuses open constructs, malformed pending source, tainted/nonresumable
sessions, and executed-source editor gates. Use `.run` or `.clear` as indicated.
A failed declaration is not appended and does not alter source or retained state.
Only one new default-kind INTEGER/REAL/LOGICAL scalar is allowed per line, with
mandatory `::`. Attributes, kind selectors, initialization, arrays, CHARACTER,
multiple names, semicolons and continuation lines are not supported for growth.
Names classified by the REPL as statement keywords are refused. Other declaration
changes remain frozen. Ordinary declarations before execution retain their
existing rules.

For this first growth subset, the existing specification region must consist of
complete single physical lines (comments/blanks are allowed). Continued or
semicolon-separated old declarations cause growth to be refused conservatively;
they remain usable in ordinary execution. A continued first executable statement
is supported when its verified starting boundary is unambiguous. All candidate
source, full-program IR equivalence, and the retained prefix are checked before
commit; there is no replay or general identifier/expression remapping.

Other source statements retain deferred
checking: malformed buffered executable source may require `.clear`. A rejected
query is never stored. Parse/type/admission failures leave runtime state intact
and do not flush pending effects. Runtime failures, including an undefined-value
or arithmetic error during a query, taint the session. Further queries cannot
resume it: use `.clear` or an explicit successful `.run` reset. Output already
produced before a runtime failure cannot be rolled back.

An admissible `.run` establishes resumable retained state. A body outside this
narrow subset still uses the ordinary interpreter on `.run`, once, with its
existing broader language support. Such a run is marked nonresumable even if it
fails: later queries reject rather than replaying its effects. Clear the buffer
to begin a new retained session. `.vars` uses the retained store after executing only the admitted pending suffix. It does not rerun prior statements or fabricate values for undefined variables. Names are whitespace-separated simple Fortran identifiers, case-insensitive, with
at most 128 names of at most 63 characters. Selection preserves request order and
duplicates. Commands themselves are lowercase. Unknown names, quoted names,
commas, subscripts and other malformed selections are rejected before pending
execution, with no partial inspection output. No-name `.vars`/`.info` use declaration
order; `.shapes`/`.sizes` use array declaration order. An empty selection prints
`(no variables)` or `(no arrays)` as appropriate. Shape is an extent, not an upper
bound; on the retained rank-one subset shape and size coincide, including zero
for empty arrays. Metadata does not read undefined elements. All four commands
honor the same admission, taint and executed-source edit gates and never modify
stored source. Valid inspection executes the admitted pending suffix once,
even when no arrays are selected.

Unlike ofort's generic command argument parser, this bounded implementation does
not accept quoted variable names. Unlike ofort's `missing: undefined` output,
unknown names reject the entire selection before any pending effects. `.info`
uses a metadata line (`name : TYPE kind=N rank=N`, and a CHARACTER length line)
followed by the established `.vars` value display rather than ofort's single
compact declaration-style line. Default CHARACTER kind is 1, independently of
internal numeric-kind metadata; arrays remain limited to the first 16 displayed
elements. These are deliberate presentation and fail-closed differences, not
full text-output parity.

## Explicit differences from ofort

This is a bounded increment, not full ofort REPL parity. In the inspected ofort
reference, top-level assignments and PRINT may execute immediately even without
autorun. Here both execute immediately only for the admitted retained-state subset. The reference expression path executes
pending source before evaluating a queried line; here query admission completes
first, so a rejected query causes no additional pending output or RNG effects. Output
already produced by immediate statements is not rolled back. These are
intentional differences, covered by transcript tests.

Full program/module input, general external source loading, advanced editing, autorun, auto-end,
general declaration reordering/growth, `let`/`const`, and broader expression calls remain deferred.
Source saves are not runtime-state snapshots. `.load` accepts only the exact `program repl_session` wrapper emitted by this REPL (CRLF is accepted). Overwrite options, `.saveq`, `.load-run`, and state-file commands are not supported. EOF never saves or executes implicitly. See [source file commands](REPL-SOURCE-FILES.md).
All source still obeys the interpreter's existing subset, including its reserved
keyword/intrinsic-name restrictions.

Input is bounded to 4,096 bytes per line, 10,000 body lines and 1,048,576 source
bytes including wrapper and temporary query. Overlong records are fully drained
so their tails cannot become commands; NUL-containing lines are rejected. Batch
stdin retains its 1 MiB source limit.

Development validation uses Linux GNU Fortran 14.2 and pipe/PTY transcripts.
Windows detection uses `_isatty`/`_fileno`, but Windows execution has not been
tested. This increment is not the certified 0.56 delivery and has not undergone
full clean maintained-suite certification. Focused transcript/native results
must not be described as a full release certification.

The supported validation profile does not enable floating-point traps. In
particular, host `EXP` overflow is checked after evaluation; custom builds with
floating-point trapping enabled may signal before a controlled diagnostic.
