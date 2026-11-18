# Default-output WRITE regression suite

Run:

```
python3 tests/stdout_write/test_runner.py
python3 tests/stdout_write/run_tests.py --candidate PATH --gfortran gfortran
```

The manifest fixes expected output and behavior independently of candidate and
GNU runs. Its 39 cases cover positional list-directed/literal formats, empty
lists/arrays, rank-three order, sections, kinds, grouped reversion, semicolon
statements, scalar CHARACTER internal-WRITE regression, registered derived
output, effects/recursive output, rejected controls/units, source-item limits,
expanded-value and CHARACTER-temporary limits, exact record bounds, undefined
values and no partial output on failure.

GNU uses `-std=f2018 -pedantic-errors -fcheck=all`: 19 safe positive cases execute,
18 boundary/runtime-negative cases compile only, and two invalid sources must
fail compilation. Undefined values and recursive defined output are never
executed by GNU. The candidate is always checked and run with a timeout.
`completed_stdout` is permitted only for a compile-only GNU runtime-negative
case; the runner requires exactly the independent prior-record prefix and no
bytes from the failing statement. Nineteen runner self-tests protect these modes.

The separate `grouped_formats` suite verifies exact nested format and reversion
semantics. Native `test_stdout_write` mutates adapter/runtime instruction fields;
`test_stdout_write_producer` checks the independent FortFront WRITE AST. Original
`assert_le` composition remains under `procedure_identifiers` with unchanged
body/provenance bytes, rather than being rewritten into this synthetic suite.
See [STDOUT-WRITE.md](../../docs/STDOUT-WRITE.md) for the supported subset.

`test_staging.py --candidate PATH --gfortran gfortran` adds ten cases using a
separate 16 MiB list-directed cap. It checks PRINT and WRITE with 4,096 and 65,536
REAL(8) values, exact 16 MiB records, one-byte-over rejection and prior-record
preservation. Six safe cases execute in GNU; four negative cases compile only.
The record-boundary oracles are generated from independent sizes and bytes;
results retain hashes/counts/timing rather than huge output bodies. The old
`list_record_limit` fixture is unchanged and now succeeds: its 65,536-character
value plus one separator is valid under the corrected list-directed cap. This
fix does not raise any literal-formatted, grouped or CHARACTER-collection cap.

0.48 promotes the unchanged `invalid_format.f90` `(z0)` INTEGER output fixture
to exact successful output `1\n`. Its historical filename is retained; no source
bytes or unrelated expectations change. B/O/Z input and REAL output remain outside
the bounded INTEGER-output feature. This suite has no source generator.
