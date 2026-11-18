# CLASS and type-bound procedures

Run from the project root, using the exact interpreter executable selected by fpm:

```
python3 tests/class_type_bound/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran --result results.json
fpm test --target test_class_frontend
```

Forty-four cases include the unchanged original date program, alias and keyword
bindings, public methods with private module implementations, CLASS forwarding,
INOUT and impure OUT receivers, scope-distinct type identities, repeated DT,
list-directed IOTYPE, empty V_LIST, multiple child writes, defined-output
expressions, status/error handling, recursive-output safety and unsupported
boundaries. Forty have direct GNU compile/run/rejection oracles; four explicitly
skip undefined behavior or unsupported input with no comparable GNU run.

The runner checks `--check` silence, expected exit status, source-time rejection
before output, stdout and requested diagnostics. GNU runs in fresh temporary
directories; it is a test oracle, never the interpreter's execution backend.
Native frontend testing independently rejects 21 metadata mutations.
