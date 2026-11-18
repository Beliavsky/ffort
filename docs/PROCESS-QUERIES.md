# Bounded process queries

The interpreter supports the GNU `CALL GETCWD(COUNT[,STATUS])` extension and
standard `CALL GET_COMMAND_ARGUMENT(NUMBER[,VALUE,LENGTH,STATUS])` in main
programs, ordinary impure functions and subroutines. Positional and reordered
keyword calls are checked against the independent producer source tree. Names
remain nonreserved: visible source procedures, generics and data declarations
win; a mismatching source generic does not fall back to an intrinsic.

## Invocation and status contract

The CLI gives the interpreted program its source filename spelling as argument
zero. It currently supplies **no positive-numbered program arguments**. Thus
NUMBER>0 yields blank VALUE, LENGTH=0 and positive STATUS, without exposing the
interpreter's flags or source-option arguments. No argument forwarding syntax is
added. NUMBER must evaluate to a nonnegative default INTEGER(4).

The reusable `execute_program` API appends optional CHARACTER `program_name`.
A root execution snapshots this explicit logical name in its execution-owned
context; nested calls inherit it and independent root calls reset it. Without an
override, the first query snapshots only the native host argument zero. No other
host arguments or environment variables are read.

A short nonzero VALUE returns the available prefix, the full argument LENGTH and
STATUS=-1. GNU14 treats a present zero-length VALUE as a positive retrieval error;
this implementation also returns positive status without fixing a processor's
numeric error value. Omit VALUE for a length-only query. An absent argument
returns blank VALUE and zero LENGTH, including when STATUS is omitted.

GETCWD reads the native process's current directory. On a too-short or zero-size
buffer, the result is blanks and STATUS is nonzero; no errno value is promised.
Omitted STATUS does not turn this processor retrieval failure into an interpreter
exception. GNU14.2's actual first keyword is COUNT, despite the online manual's
C spelling; positional syntax is recommended. The exact compiler-source evidence
and C/CWD rejection cases are in `tests/process_queries/README.md`.

## Storage, effects and resource limits

Outputs must be distinct whole local scalar default CHARACTER or INTEGER(4)
variables. Already-allocated scalar CHARACTER is supported, without automatic
allocation or changing its length. Main-program SAVE storage remains subject to
its existing initializer rules. Dummy, optional, host/module, pointer, CLASS,
parameter, procedure-SAVE and array/substring/component outputs are outside this
bounded contract. Direct NUMBER/output variable aliases, duplicate outputs and
active DO-counter outputs reject. A NUMBER expression temporary may reuse an
output symbol after its value has been captured.

Undefined output values are not read. Descriptor, allocation, alias and active
counter checks run before the native inquiry or output commit. The result buffer
and INTEGER outputs are staged until successful evaluation and work accounting;
failures do not partially commit this query's output actuals. This is not a
rollback of side effects caused while evaluating an input expression or earlier
statements. A normal nonzero processor STATUS is an inquiry result, not an
interpreter failure.

PURE/SIMPLE procedures and every PURE/SIMPLE ancestor on the active call stack
forbid these queries. Existing external I/O and shared-storage restrictions are
unchanged. The producer's impure registry also rejects GETCWD in DO CONCURRENT;
that construct is not added to the interpreter subset.

CHARACTER query buffers and the logical program name each have a 65,536-character
cap. New explicit allocations use STAT and return controlled diagnostics on
failure. Each query charges 64 fixed work units before native inquiry and charges
copied/padded characters before committing outputs. The existing step, array,
CHARACTER-storage and output caps are unchanged. Allocation failure paths are
reviewed, not claimed as deterministically fault-injected.

This does not implement GETARG, COMMAND_ARGUMENT_COUNT, GET_ENVIRONMENT_VARIABLE,
GETCWD function syntax, command execution, file opening or general external READ.

## Evidence and remaining full-source boundary

The exact original `exe_name` body (utility lines549–557, including CRLF and its
literal backslash) executes against GNU14 in a controlled cwd and logical argv0.
Its 1000-character output is compared byte-for-byte, not whitespace-normalized.
The synthetic suite has 100 cases: 34 defined GNU executions, 38 compile-only
boundaries and 28 GNU compilation rejections. Undefined/invalid programs are not
executed as reference behavior. There are 28 adversarial harness tests, 328 native
public-IR/source/runtime/context checks and 12 direct producer checks.

The complete unchanged utility source still rejects its 100-million-element
array declaration at9329:55. The separately authorized working copy changes only
`nmax=10**8` to `nmax=10**5`; no other source bytes are changed. With these queries,
its check and run both stop at601:10 on `read (iu,"(a)") text` in read_words_line.
That is external formatted-unit input, so source execution has not begun. The
whole working copy independently compiles and runs under GNU with explicit GNU
dialect. No complete FortFront utility execution is claimed.

The recorded platform is GNU Fortran14.2/Linux. Windows has not been executed.
Vendor patch0085 contains only producer registration/classification metadata.
See `tests/process_queries/README.md` for portable commands and exact provenance.
