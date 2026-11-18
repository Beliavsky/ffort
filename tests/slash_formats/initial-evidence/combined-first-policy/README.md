# Bounded slash record editing: rebased source-only draft

Rebased on certified FortFront 0.48 without changing the formatter delta. Only
fi_runtime parser, type-association validation and staged renderer helpers change;
no vendor metadata, output-unit resolution or commit implementation changes.
The initial slash draft and all 37 initial Fortran fixture bodies remain unchanged
in their original workspace. The current suite retains those exact bodies and
adds seven cases for pending suffix preservation, list exhaustion, statement
atomicity and genuine operation/staging cap boundaries.

44 source cases pass their declared GNU stages: 34 executions and 10 compile-only
bounded-runtime references. All 24 records of unchanged demo_btest are byte-exact.
Thirty comparator checks and 44-file generator replay pass. The utility closure
preserves three original CRLF bodies and passes a separate GNU clock observation:
blank first record, exact label/F9.3 shape and finite nonnegative elapsed time,
not matching numerical clock samples between implementations.

No candidate or native test has run. Negative candidate diagnostics deliberately
remain unpinned, so the runner will record and fail those rows until the shared
app establishes exact stage/location evidence. The native public-IR source is a
source-only draft covering slash grammar, bounded repetition, exhausted-list and
colon suppression, scalar internal/defined-child boundaries and forged formats.

## Limits and correction to the initial oracle

The existing 65536-character renderer staging buffer excludes the final host
record terminator. Therefore the unchanged `(65536/)` fixture legitimately
expects 65537 newline bytes; the initial draft's rejection expectation was wrong.
GNU confirms the corrected oracle. A separate runtime format with 65536 slashes
plus a literal exceeds the staging cap. The old 262145-repeat fixture still tests
repeat-count rejection; four individually valid 65536-repeat T1 groups now test
the actual 262144-operation traversal limit. Initial evidence is retained.

Reached slash requires another record. Scalar internal and defined child output
remain bounded rejections, but an earlier exhausted data descriptor or colon may
terminate formatting before slash. Output remains staged until all format/type,
value and capacity checks pass. Failed statements cannot emit a partial slash
record or overwrite a previously committed pending suffix.

## Commands in this directory

```
python3 self_test.py
python3 check_generator.py
python3 run_tests.py --candidate /path/to/shared-cli --gfortran /path/to/gfortran --result /path/to/results.json
python3 check_original_utility.py --candidate /path/to/shared-cli --gfortran /path/to/gfortran --result /path/to/utility-results.json
```

The utility command also requires the separate runtime stdout-unit feature.
`native-plan.py` at the bundle root prints (does not execute) native commands from
the current shared FPM compile database, retaining every recorded flag including
split-debug settings. There is no private app/cache build or native compilation.
