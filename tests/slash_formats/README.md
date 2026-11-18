# Bounded slash record editing

FortFront 0.49 adds `/` and positive repeated slash edits to its existing bounded
formatted output renderer. Quoted slash remains literal. Leading, trailing,
adjacent and nested slashes, permitted omitted commas, reversion, unlimited
formats, colon/list exhaustion, T/TL/TR and nonadvancing output compose without
changing output-unit resolution, file access or the staged commit mechanism.

The focused suite has 44 source cases: 34 exact-byte successes, two static
scalar-internal/defined-child compile-time boundaries and eight runtime failures.
On immutable combined preview `1184da7445c3eed3b680d0429e24a4cd2125ed317622f2a337f81f71bc200130`,
all 44 pass their pinned contracts. GNU independently executes the 34 successes
and compiles the ten bounded-runtime/subset reference cases. All 24 records of
unchanged `demo_btest.f90` compare byte-for-byte. The source-only initial draft
and provisional failure expectations are retained under `initial-evidence`.

Thirty comparator and 125 adversarial policy checks enforce exact record bytes,
successful empty stderr/check stdout, negative stage/status/source path/line/
column/message, no spurious output, and clock-output shape. The generator replays
all 43 generated sources plus the manifest exactly. All original/initial Fortran
bodies are unchanged. Central shared-profile native validation passes 55
assertions using the exact `test/test_slash_formats.f90` source.

The separate timing closure preserves three original utility routine bodies,
including CRLF bytes, with provenance in `utility-provenance.json`. Both candidate
and fresh GNU executions produce the required leading blank record, exact label,
F9.3 field and nonnegative finite elapsed time. Clock values are not compared
numerically across implementations. This is a closure pass, not a full-utility
pass. The full authorized working utility still reaches a later unsupported
internal WRITE array-element target, handled separately from this feature.

## Limits and preserved boundaries

The existing 65536-character renderer staging buffer excludes the final host
record terminator. Therefore `(65536/)` legitimately emits 65537 newline bytes.
The initial draft's rejection expectation was wrong; that first evidence is
preserved. A runtime format with 65536 slashes plus a literal tests real staging
overflow. Four individually valid 65536-repeat T1 groups test the existing
262144-operation traversal limit. Repeats, 64 descriptors and depth31 remain
bounded; no resource cap was raised.

A reached slash needs another record. Scalar internal and bounded defined-child
output remain unsupported for that case; an earlier exhausted data edit or colon
can stop before the slash, including for empty lists. Static known violations
reject at check; dynamic violations reject during execution. Output is staged
until all format/type, value and capacity checks pass. A failed statement cannot
emit a partial slash record, and previously committed nonadvancing bytes and
pending high-water suffixes are preserved.

## Commands

```
python3 tests/slash_formats/self_test.py
python3 tests/slash_formats/test_policy.py
python3 tests/slash_formats/check_generator.py
python3 tests/slash_formats/run_tests.py --candidate /path/to/cli --gfortran /path/to/gfortran
python3 tests/slash_formats/check_original_utility.py --candidate /path/to/cli --gfortran /path/to/gfortran
```

The last command also requires the separate runtime stdout-unit feature. These
checks are registered in `scripts/verify.py`; the native source is discovered by
the existing native verification workflow.
