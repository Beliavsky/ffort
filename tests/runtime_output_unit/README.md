# Runtime integer units restricted to standard output

WRITE may use a whole scalar INTEGER(4/8) name as its unit. This includes
parameters, local/module variables, readonly or writable dummies and supported
host-associated variables. The value is evaluated once and must equal this
processor's ISO_FORTRAN_ENV OUTPUT_UNIT. The implementation never passes an
interpreted integer to a host WRITE unit and never opens a file. Any other
value, including negative values and an integer named `output_unit` with the
wrong value, receives a source-located runtime diagnostic explicitly stating
that file output is unsupported. An undefined or absent unit rejects safely.

Literal unit numbers, arithmetic/function unit expressions, array elements,
arrays, POINTER and ALLOCATABLE units remain outside this bounded slice.
`WRITE(*,...)` and a directly imported OUTPUT_UNIT retain their existing static
representation. Existing defined formatted child WRITE continues to use its
matching UNIT dummy and virtual parent transfer, not this new route.

The unit is validated before the format and output list are evaluated. Existing
staged list/formatted output, runtime CHARACTER formats, B/O/Z edits, defined
formatted transfers, ADVANCE, pending-record state, caps, and I/O effect and
recursion guards remain unchanged. A rejected unit cannot publish a partial
record or invoke a defined-output callback; a previously written pending record
remains untouched. The IR reuses OP_PRINT: A is the validated unit expression
and SYMBOL its exact base. A=0 preserves existing PRINT/static-unit semantics.
The adapter independently checks the source declaration identity and kind.

## Verification

```sh
python3 tests/runtime_output_unit/test_runner.py
python3 tests/runtime_output_unit/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The focused corpus covers kinds, parameters/dummies/module/captured bindings,
formats, list output, nonadvancing output, defined output, invalid targets,
absence/undefinedness, failure ordering and forbidden procedure contexts.
GNU is executed only for supported standard-output cases. Unsupported file-unit,
undefined-value and interpreter-subset cases are compile-only GNU checks; no
GNU test opens a file for them. GNU accepts concurrent I/O, while the interpreter
retains its narrower concurrent-body subset. Empty `()` formats remain an
existing formatter boundary, not a new unit capability.

The exact CRLF bodies of `init_wall_time`, `print_wall_time_elapsed` and
`default_integer` from xutilities are in the separate original wrapper, with
hashes and line ranges in provenance.json. The unit-only candidate checks that
wrapper successfully, then encounters its pre-existing unsupported slash format
at execution. Its GNU elapsed-time output is a separate host observation, never
a byte-equal oracle. Combined execution belongs to the companion slash-format
verification. The unchanged authorized full utility advances to its next
independent generic REPEAT resolution gate; this feature does not claim that the
whole utility executes.

The native target tests 61 descriptor variants and 15 instruction variants
through independent public, adapter and runtime guards, plus source binding
identity. The runner preserves exact CHARACTER records and empty streams, and
records immutable candidate/source hashes. No existing Fortran fixture is
rewritten. Separate expectation-only migrations preserve both affected PURE
rejections and source-shadow unit rejection, while promoting the three genuine
standard-output cases.

Integrated 0.49 stdout-unit plus slash output now executes that exact original
timing closure unchanged. `tests/slash_formats/check_original_utility.py` checks
the blank first record, exact label, F9.3 field and finite nonnegative elapsed
time separately for GNU and candidate, without comparing timestamp values.
The unit-only failure observations above remain historical evidence.
