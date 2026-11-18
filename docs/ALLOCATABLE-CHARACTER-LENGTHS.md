# Specification-length allocatable CHARACTER dummies

Mandatory ALLOCATABLE CHARACTER dummy arrays of rank one, two or three may use
bounded scalar INTEGER specification lengths, for example:

```fortran
character(len=len(words)), allocatable, intent(out) :: values(:)
```

The dummy is nondeferred: the actual must also be a nondeferred whole allocatable
array with exactly the evaluated element length. This equality is checked even
when the actual is unallocated or has zero elements. The existing CHARACTER(*)
and deferred CHARACTER(:) contracts remain distinct. OPTIONAL specification-length
dummies and ordinary nonallocatable specification-length dummies remain explicitly
unsupported; valid GNU compilation of those cases is not candidate support.

## Entry-time and storage rules

IN, OUT and INOUT association first establishes all argument descriptors and input
values, independently of positional or keyword ordering. The safe specification
expression is evaluated once for the activation before local arrays or procedure
statements execute. The existing bounded expression subset supports scalar input
parameters, safe array/length inquiries, COUNT masks and bounded PURE specification
functions. Optional/mutable-local/impure dependencies are not silently accepted.

Negative lengths become zero. Lengths above 65,536 are rejected. The
16,777,216-live-CHARACTER-array-byte limit is unchanged. The independently
configured array cap defaults to 1,000,000; 10,000,000 requires an explicit rebuild.
The synthetic zero-length CHARACTER STAT probe is generated at configured cap+1;
regenerate it with `tests/allocatable_character_lengths/generate_cap_case.py` after
reconfiguration. Its manifest/provenance hashes are checked before execution.
Each recursive activation keeps its own verified length. Changing an INOUT scalar
used in the expression does not change that activation's CHARACTER length.
LEN reads descriptor metadata without reading uninitialized elements. Actual
reads, including reads of uninitialized zero-length elements, retain definedness
checks. The checked descriptor is used by ALLOCATE with STAT, deallocation,
assignment reallocation, nested forwarding and copyout. Existing alias rejection
and allocation-status semantics are retained. Association failures occur before
procedure-body output or caller descriptor copyout.

The parser, independent FortFront adapter and public runtime validate declaration
and expression metadata. A forged positive length cache cannot bypass a dynamic
expression even if the dummy is unused. Source-text identity is checked by the
adapter; a valid alternate assumed-length IR is not claimed to encode its former
source spelling. No producer patch is needed for this extension.

## Exact original routine and regression scope

`tests/allocatable_character_lengths` contains 35 source cases, 25 harness checks
and 181 native assertions. Five wrappers retain all 865 bytes and 27 CRLF endings
of the original compress body (xutilities lines 9648–9674). Three execute successful
cases, one verifies the original factors-size ERROR STOP, and one rejects an
output-length mismatch. Only wrappers/drivers are new. GNU references distinguish
14 successful executions, one expected ERROR STOP, 15 compile-only safety/subset
cases and five compilation rejections. Unsafe aliases, undefined reads and length
mismatches are not executed as GNU runtime oracles.

The old `tests/findloc/utility_compress_declaration_blocked.f90` bytes are retained;
its historical filename is unchanged. Its manifest now expects successful
checking and execution of its empty main, not actual compress invocation.

The untouched full xutilities input still rejects at 9329:55 because xbig(10**8)
exceeds both supported element-cap configurations. An explicitly separate diagnostic copy changing
only nmax to 1000 advances past compress to module finalization at 9675:1:
“Intrinsic-symbol overload requires a derived type operand.” This is a source
checking checkpoint, not full-source acceptance or execution. The original source
is never reduced in place, and --max-steps does not change storage limits.
