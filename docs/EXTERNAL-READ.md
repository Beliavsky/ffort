# Explicit bounded input records

The interpreter supports `read(iu,'(a)',iostat=status) line`, with a declared
scalar INTEGER(4/8) unit variable, literal A-only format, one whole writable
scalar default-CHARACTER target, and optional scalar INTEGER IOSTAT. UNIT/FMT
keywords are accepted in that order. Literal format case, spaces and tabs are
insignificant. Widths, extra edit descriptors, runtime formats and other controls
remain unsupported. External input is forbidden in PURE/SIMPLE procedures and
ordinary functions; ordinary subroutines and explicitly IMPURE ELEMENTAL functions may use
it under the same external-effect rules as output.

## Explicit authority and file semantics

```
fortfront-interpreter --input 27=words.txt program.f90
```

Only a requested binding opens a file, read-only, after source compilation succeeds.
`--check` validates option syntax but never opens input files, even nonexistent ones.
Interpreted source cannot open a path, access stdin, inherit a host unit or create
an implicit `fort.N` file. An unbound or invalid unit is a checked runtime error,
not a request to access the host. No OPEN, CLOSE or external WRITE is added. BACKSPACE now repositions only
the explicitly bound in-memory records as described below. Unit identifiers are positive INTEGER(4) values, including when represented
by a source INTEGER(8). There are at most 32 bindings, each at most 1,048,576 bytes,
and at most 4,194,304 bytes across all bindings.

The CLI loader accepts regular files only. POSIX opens are read-only/nonblocking,
then checked with fstat before reading; symbolic links are rejected where
O_NOFOLLOW is available. The guarded Windows implementation checks a read-only
handle for disk-file type and rejects directories and reparse points. Devices,
FIFOs and directories are not read. File size and complete-read checks detect
short or growing files; this is not an immutable filesystem snapshot and does not
promise detection of concurrent same-size content changes. No input file is
written, truncated or created.

A compatible C compiler is now needed in addition to GNU Fortran and fpm. FPM
builds `src/fi_input_file.c` into the package library and links it into the CLI and
native tests. The standard shell/PowerShell verifier remains the entry point.
The POSIX branch is executed on Linux; Windows remains source-reviewed only,
not a claimed Windows runtime result. The loader uses no extra external library.

Embedding applications can bypass filenames entirely: pass an array of public
`input_unit_t` values to `execute_program(...,input_units=bindings)`. Each entry has
`unit`, allocated CHARACTER `data`, one-based `position` initialized to 1,
and `endfile` initialized false.
The caller grants those bytes only. The runtime has no file-opening path.
Descriptors, uniqueness, aggregate limits and cursors are validated. Procedure
calls share the same advancing cursor. Separate caller-owned tables do not share
state, and an embedding caller can explicitly reset the cursor and endfile flag for a new execution.

## Records and errors

Each successful READ consumes one complete LF or CRLF record, discarding its
terminator. A final nonempty record need not end in a newline. Empty files and
exhausted records report EOF; a final newline does not create an extra record.
Empty records are valid. Data is truncated or blank-padded to the target length,
including zero length, and the entire external record is advanced. Each record
is limited to 65,536 characters and consumes the work budget byte by byte. NUL,
other control bytes except tab, bare CR, and DEL are rejected as safety errors.

IOSTAT is zero on success, -1 on the first EOF, and positive on a read past
the endfile record. EOF/error makes the data target undefined;
without IOSTAT it is a checked runtime error. Binding/metadata/resource errors
remain safety diagnostics, not recoverable IOSTAT values. All target descriptors
are checked before transfer, including scalar allocatable allocation status,
absent OPTIONALs, active counters, writable intent and alias restrictions.

## Mixed internal list input

Scalar CHARACTER internal records now admit whole default-CHARACTER scalar and
rank-one through rank-three targets alongside INTEGER/REAL targets. Fixed and
allocated lengths are retained: input pads/truncates and never reallocates.
Existing numeric conversions and limits remain. Before transfer, expanded CHARACTER
target bytes must fit the 16 MiB limit and the existing live CHARACTER array
storage check; this includes fixed arrays and rejects oversized transfers even
when null values might otherwise avoid materialization. Runtime local lengths
use their frozen entry values. Quoted tokens may contain blanks,
commas, slashes or stars, and doubled matching quotes encode one quote. Empty
quoted strings are values. Nondelimited strings, repeats, nulls and slash
termination are bounded; repetitions are consumed lazily. A nonnull repeated
value cannot cross input type or kind, while CHARACTER lengths may differ.

Nulls and slash preserve old values and definedness. On input error or EOF all
input-list targets become undefined, including earlier successful transfers.
IOSTAT sign is portable; specific positive values are processor-dependent.
Unterminated quoted tokens are deliberately rejected by the bounded lexer even
where GNU accepts them. Source-record/target overlap and repeated/aliased targets
are rejected. LOGICAL, COMPLEX, derived targets, elements/sections and implied DO
remain outside this extension.

## Original utility evidence

Five fixtures preserve the complete `read_words_line` body, xutilities lines
591–624, with byte-exact CRLF provenance. The surrounding module, `default`
helper and driver are synthetic. Cases cover ordinary/quoted words, zero and
negative counts, and the original echo branch. GNU reads fixture-local `fort.27`
files; the candidate reads only explicit bindings to generated temporary files.
No test reads user files, stdin, credentials or other host data. Whole-library
acceptance is not implied by one unchanged original body.

The constructor gate is covered by bounded constructor implied-DOs. External list-directed READ and BACKSPACE
boundaries remain separate work. Source preservation and focused verification are
recorded by `tests/external_read/run_tests.py`; CLI loader checks and native
metadata/runtime tests are separate from full release verification.

## Verified checkpoint

The frozen app passes 50 focused source/GNU cases: 27 GNU executions and 23
compile-only subset/safety references. All five unchanged original-body cases
execute with byte-exact GNU stdout, including the echo branch. Independent native
guards pass 184 metadata/producer checks and 293 runtime checks. The CLI loader
has 22 Linux checks, and the differential harness has 20 self-tests. All 81
existing internal READ cases pass after reclassifying the retained uninitialized
CHARACTER-target fixture as a runtime failure rather than unsupported syntax.
The production CLI/static library and both focused native programs were built
with the existing debug profile/library; no release-wide native pass is claimed.

The untouched full xutilities file still stops at its independent default-cap
violation, line 9329:55. The authorized nmax=100000 working copy still stops at
GETCWD line 553:12 when tested without the separately supplied process-query
patch. Only the combined release can establish the next full-working-source gate.

## External list-directed input and BACKSPACE (0.47)

`read(iu,*,iostat=status) n, values, words` accepts a declared whole scalar
INTEGER(4/8) unit variable, up to 64 distinct whole local INTEGER/REAL(4/8) or
default-CHARACTER targets, and optional distinct local INTEGER IOSTAT. Numeric
and CHARACTER scalars and rank-one through rank-three arrays share the existing
internal-input descriptor, allocation, intent, OPTIONAL, active-counter and alias
guards. Empty input lists and zero-sized targets still consume one record.
The original formatted `(A)` path and its narrow single-scalar target contract
remain unchanged. UNIT/FMT keywords are accepted in that order.

Records are fetched lazily as needed to fill the input list. End-of-record is a
blank separator outside a quoted CHARACTER value. A leading comma on a new record
can finish the preceding value separator; an already consumed comma is not
consumed twice. Quoted CHARACTER tokens can continue across records without
inserting a newline, retaining spaces at record edges. Matching doubled quotes,
repeats, nulls and slash termination follow the bounded internal-input rules.
Repeated nonnull input cannot cross type or kind in this subset. Each token is
limited to 65536 characters, each record to 65536 characters, and the existing
1 MiB per-unit/4 MiB aggregate input and 16 MiB CHARACTER transfer limits remain.
Every fetched record is fully validated and charged to the shared work budget
before its cursor advances. The unused suffix of the final consumed record is
discarded. No target array is reallocated.

On conversion error or EOF every input-list target becomes undefined, including
previously transferred items. Null input and slash preserve old values and
definedness. IOSTAT is zero on success, negative for EOF, positive for conversion
error or past-endfile; specific positive codes are processor-dependent. Without
IOSTAT these conditions are checked runtime failures. Nonfinite real input is
rejected under the existing finite-value policy. Binding, metadata and resource
violations remain safety errors, not recoverable IOSTAT conditions. This is not
a promise to roll back arbitrary statement side effects after a safety failure.

`backspace(iu)`, `backspace iu`, and `backspace(unit=iu,iostat=status)` move to
the beginning of the last consumed record in that same explicitly bound table.
At the initial point the operation is a successful no-op. After EOF, the first
BACKSPACE clears the endfile state without moving past the preceding data record;
a second BACKSPACE reaches that record. LF, CRLF, blank records and final
unterminated records retain their byte boundaries. Procedure calls share the
caller-owned cursor, while distinct binding tables remain independent. Invalid
or unbound unit numbers are safety errors even with IOSTAT. No REWIND, ENDFILE,
ERR branching, stdin, implicit `fort.N` files or source-selected filenames are
introduced. External effects retain the existing PURE/SIMPLE/ordinary-function
and nested-I/O restrictions.

The new `tests/external_list_read` suite preserves ten exact original
`read_alloc_char` closures, including its actual `present_and_true`,
`default_logical` and `default_character` dependencies. Both next-record and
same-line/BACKSPACE paths, empty and negative counts, and original print branches
are exercised against GNU. The complete authorized `nmax=100000` working utility
source passed that constructor in the descriptor-length checkpoint, but
then rejected at1192:18 on `call system_clock(old_time_)` in `init_wall_time`. This is not a whole-library
compile or execution pass. The original and one-byte-adapted source remain intact.

At the integrated 0.49 checkpoint, timing, runtime stdout-unit selection and
generic REPEAT fallback advanced the same byte-preserved working source to
2376:11, array-element internal WRITE in `integer_labels`. In 0.50 the bounded
element-file and numeric rank-three gather additions advanced that source to
2493:24, rank-one CHARACTER vector gathering, then excluded. Those are historical
checkpoint observations, not full utility execution. See the
[historical 0.50 scope](RELEASE-0.50.md). The bounded 0.52
[CHARACTER gather](CHARACTER-GATHER.md) and
[bare read-only actual](BARE_CHARACTER_GATHER_ACTUAL.md) additions advanced the
same preserved working source to the historical numeric rank-one gather boundary
at2678:36. The untouched original retains its 9329:55 storage-cap rejection.

## numeric-gather progression

Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed. See [numeric gathering](NUMERIC-VECTOR-GATHER.md) for the separate actual-association contract.

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../tests/utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
