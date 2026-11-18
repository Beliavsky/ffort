# Bounded default-output WRITE

The supported external forms are positional `WRITE(*,*) items` and
`WRITE(*,literal_format) items`. Both allow an empty item list and share the
existing PRINT instruction, evaluation order, list-directed output policy and
literal formatter. The literal format grammar includes the bounded nested
repeat groups in [GROUPED-FORMATS.md](GROUPED-FORMATS.md).

Supported scalar and rank-one/two/three INTEGER(4/8), REAL(4/8), default LOGICAL
and CHARACTER items expand in Fortran element order. Existing scalar derived
values use their registered defined-output binding. A callback's supported child
WRITE remains directed to its provided unit, not to a newly opened stream.
Internal scalar CHARACTER and whole array-element WRITE retain their separate
target and single-record contract; see [element files](INTERNAL_WRITE_ELEMENT.md). No new opcode, file handle, unit mapping or operating-system file
access is introduced.

External output is allowed wherever PRINT is allowed: main programs, impure
subroutines and explicitly IMPURE ELEMENTAL functions. PURE/SIMPLE procedures
and ordinary functions cannot perform external output directly or transitively.
Recursive I/O during an item expression or a defined-output callback is rejected.

## Deliberate exclusions

This feature does not accept keyword UNIT/FMT, numerical or variable external
units (including numerical unit 6), dynamic/label formats, NAMELIST, ADVANCE,
IOSTAT, IOMSG, ERR or other control specifiers. Existing registered defined-output
child WRITE is the only exception for its already supported callback controls.
No READ, OPEN/CLOSE, files or interactive input is added. Unsupported forms fail
during checking rather than falling back to the host compiler's I/O system.

## Staging and limits

All item values are collected and checked before rendering. The complete output
of one statement is staged before its external write. A later undefined item,
format/type mismatch, recursive-output attempt or limit error emits no partial
record from that statement. Previously completed statements remain visible.
This does not promise rollback of other callback side effects, nor can a host
operating-system output failure be rolled back.

- At most 64 source items and 65,536 expanded scalar values per statement.
- At most 16 MiB of collected CHARACTER data, checked before appending each
  scalar value or array's elements to the collected list. The expression
  evaluator retains its own independent allocation limits.
- Literal-formatted output retains its 65,536-character aggregate staging cap,
  including record-reversion separators but excluding the final output newline.
- List-directed PRINT and WRITE have a separate 16 MiB staged-record cap,
  including separators but excluding the final newline. This preserves large
  numeric lists, including the established 4,096 REAL(8) random-output smoke and
  the maximum 65,536 expanded numeric values. A CHARACTER-only list must leave
  room for its initial separator within that independent output cap.
- The list-directed staging buffer grows geometrically, never beyond 16 MiB.
  Remaining-space checks happen before each growth or append, only initialized
  bytes are copied, and one exact-size record is produced before external I/O.
  This avoids quadratic copying as long numeric lists grow. Allocation failure
  remains a checked error; no partial record is written.
- Formats have at most 64 descriptor/literal/group-boundary nodes, positive
  repeat counts up to 65,536 and a 262,144-operation traversal cap. Details and
  the precise reversion rule are in [GROUPED-FORMATS.md](GROUPED-FORMATS.md).

The independent frontend and runtime reject unused or inconsistent PRINT
instruction metadata. Producer tests cover the default-unit AST representation,
including the unallocated empty item list. Mutation tests do not depend on the
parser to protect runtime entry points.

## Verification and original utility

`tests/stdout_write/run_tests.py` has 39 candidate cases. GNU Fortran independently
executes the 19 supported safe positive cases, compiles 18 negative/boundary
cases without executing undefined programs, and rejects two intentionally
invalid sources. Byte-exact expectations are used for fixed formatted records,
empty output and boundary-sized records. List-directed processor-dependent
numeric padding uses token comparison. A runner self-test verifies that a
failed later statement preserves precisely the prior completed record.

The separate ten-case staging suite tests PRINT and WRITE with 4,096 and
65,536 REAL(8) values, exact 16 MiB CHARACTER records, one-byte-over rejection
and preservation of prior completed records. Six positive cases execute in GNU;
four cap-negative cases compile only. Results store byte counts, hashes and
elapsed times instead of multi-MiB log payloads. The unchanged random-distribution
smoke is also retained under `mean_programs_independent`. Nineteen runner self-tests
check comparison and rejection contracts. The grouped formatter has its own
39-case suite. Native tests cover four producer
shapes, 16 independent instruction mutations at both frontend and runtime,
format-program checks and grouped output. Historical valid stdout/group examples
are promoted to GNU execution without changing their Fortran source.

Combined with version 0.33's contextual PROCEDURE naming, both wrappers around
the byte-preserved original `assert_le` body from `xutilities.f90` lines 8187–8197
execute. The stop branch prints
`in unit, left right = 3 2 need left <= right, STOPPING` and the interpreter's
existing bare STOP notice on stderr. The pass branch prints `assert_le passes`.
The original body and provenance remain in `tests/procedure_identifiers`.
The isolated stdout-WRITE checkpoint stopped at line 8663, column 63, for
`xmask(size(xx,1))`. The combined 0.34 release also supports that bounded
allocatable-dummy inquiry and contextual CHAR naming, and reaches the unsupported
nested quick_sort procedure structure at 8926:16. Neither checkpoint claims
whole-file utilities execution.

## Later runtime-format milestone

The original exclusions above describe the initial stdout WRITE milestone.
Whole scalar CHARACTER runtime formats, bounded named UNIT/FMT controls and
literal YES/NO nonadvancing stdout are now supported under
[RUNTIME-FORMATS.md](RUNTIME-FORMATS.md). Four unchanged historical rejection
fixtures are promoted to GNU execution: three formatted byte-exact checks and
one existing processor-dependent list-directed token check. No source is rewritten.
