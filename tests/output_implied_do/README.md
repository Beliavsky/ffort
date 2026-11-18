# Output implied-DO independent regressions

The suite invokes a supplied interpreter executable directly. It does not build
the interpreter, invoke fpm, or use GNU Fortran as an execution backend. GNU is
used in separate temporary directories solely for independent reference checks.

```sh
python3 tests/output_implied_do/run_tests.py --self-test
python3 tests/output_implied_do/check_generator.py
python3 -m unittest discover -s tests/output_implied_do -p test_runner.py
python3 tests/output_implied_do/run_tests.py \
  --candidate /absolute/path/to/frozen/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran
```

`--candidate` and `--gfortran` can also run separately. `--only REGEX` selects
fixtures. `--result FILE` selects the JSON report. The executable's SHA-256 is
checked before and after the full run. Source and committed oracle fingerprints
are checked before execution. Compiler/run statuses, complete stdout/stderr,
flags, executable versions, source hashes and manifest identity are retained.
Every successful check and execution requires **truly empty stderr**, including
no whitespace. `--check` stdout must also be truly empty.

## Coverage

- PRINT and stdout WRITE with list-directed and constant literal/PARAMETER
  formats; internal scalar CHARACTER WRITE, including a function doing internal
  implied-DO output while called from an outer implied-DO output statement.
- INTEGER(4/8) counters and conversion, positive/negative/zero-trip loops,
  final-counter values, source-order items and repeated counters in separate
  sibling loops, frozen controls, nested outer-dependent controls and SIZE.
- INTEGER/REAL/LOGICAL/CHARACTER leaves, whole arrays through rank three, dynamic
  and reversed sections, zero-length CHARACTER values, zero-sized array leaves,
  impure elemental scalar/array functions and per-iteration cache refresh.
- Source-order array snapshots before subsequent function mutations. These are
  defined GNU execution oracles; direct self-aliasing of an internal output file
  is not presented as a portable GNU execution oracle.
- Exactly eight/nine nested levels, 64/65 objects in one loop, 65,536/65,537
  expanded values, 65,536/65,537 total iterations, nested total-iteration counts,
  16 MiB/16 MiB+1 collected CHARACTER data and the shared work budget.
- Local counters shadowing a module name, and nonreserved CHAR/CSHIFT array names
  that must resolve as array elements rather than intrinsics. TRIM remains an
  explicit reserved-name rejection, not an implied extension to identifier rules.
- Checked zero stride, undefined controls/late leaves, bounds failures, checked
  narrowing and final-increment overflow, format mismatch and short internal
  destination failures. Each retains an earlier completed stdout record exactly
  and may emit no bytes from the failed statement.
- Unsupported dummy, host/module, saved, allocatable/pointer and noninteger
  counters, derived leaves, READ implied-DOs and substring internal
  destinations. These retain their existing language/subset boundaries.

A CLI process ends on a runtime error. The CLI atomic-output cases prove absence
of partial stdout, **not post-error internal target contents**. Direct inspection
of an unchanged internal CHARACTER destination requires a native API test.

## GNU stage policy and exact comparisons

Success cases compile and execute with GNU, using `-std=f2018 -pedantic-errors
-fcheck=all -O0 -ffree-line-length-none`. Expected stdout snapshots are committed.
GNU-success compilation and execution must have empty stderr. Every candidate
negative is GNU compile-only or GNU compile-rejection; no checked-runtime safety
failure executes under GNU. There are no skipped or compiler-fallback oracles.
GNU accepts the syntax of nested counter reuse despite the invalid control reuse;
that particular fixture is explicitly compile-only and never executed. Its GNU
acceptance is not claimed as a valid-language semantic oracle.

List-directed numeric records compare integers and finite Decimal values exactly,
including INTEGER(8) values above 2**53 and the sign of zero. They do not convert
through floating point or use approximate tolerances. NaN tokens, including
signed/case-varied payload forms, and Infinity are rejected. Decimal REAL tokens
at or above the exact binary64 round-to-nearest overflow midpoint
(2**1024 - 2**970) are rejected; values just above HUGE that still round finite
remain admissible. Tiny nonzero Decimal values stay exact and never underflow
to zero during comparison. The integer-to-integer path remains exact. D/E exponent spelling and
horizontal numeric field padding may differ. Record count, blank records, final
newline and token count may not differ. Formatted and CHARACTER records compare
byte-for-byte, with no stripping or newline normalization.

The complete original `demo_trim` source is byte-for-byte preserved. Its committed
reference output includes every original record. **Output record 4** contains two
list-directed integers; only its horizontal numeric padding is processor-dependent
and compared by exact numeric tokens. All other demo output records, including
all CHARACTER spaces and newlines, must match GNU byte-for-byte. The suite does
not claim whole-demo byte equality. Three adversarial tests enforce this narrow
exception, alongside integer precision, signed-zero, NaN, record-boundary,
CHARACTER-whitespace, empty-stderr and partial-output checks. There are 45
adversarial harness checks in total.

## Unmodified upstream procedures

`provenance.json` records the unchanged original `xutilities.f90` SHA-256 and the
exact line ranges and raw body hashes for `join` (844–861), `join_csv` (884–896),
`join_csv_suffix` (898–912) and `join_suffix` (914–925). Their bodies retain the
original CRLF bytes, including comments and trailing spaces. Only surrounding
module/main drivers are new. Each wrapper covers multiple, singleton, empty and
all-blank word vectors. The runner reextracts and compares the exact body bytes.

The original `demo_trim` is pinned to M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`, SHA-256
`9d8b003fbaadf085f7e73239c1685a12df49aa55d7fa21940e189566a6c4e83c`.
Its [upstream source](https://github.com/urbanjost/M_intrinsics/blob/fc14233036d910e3678d350efc24609e11475067/example/demo_trim.f90)
is copied without edits or line-ending normalization.

`generate_cases.py` regenerates synthetic fixtures and wrappers from the original
utility source and committed demo copy. `--demo-source FILE` can explicitly select
an upstream demo file, whose pinned hash is still mandatory. Oracle regeneration
is a separate, explicit maintainer operation:

```sh
python3 tests/output_implied_do/run_tests.py \
  --gfortran /absolute/path/to/gfortran --record-oracles
```

Normal runs never regenerate expected results. Regeneration writes snapshots only
if every selected GNU stage passed and cannot be combined with a candidate run.

`check_generator.py` copies only the generator, original utility input and
original demo input into a fresh temporary tree. It reconstructs all 101 fixtures
and compares their raw bytes plus `manifest.json` and `provenance.json`. It also
proves every committed fixture, both metadata documents and both generator/input
files are unchanged afterward. `generator-replay-results.json` records all 103
byte comparisons and SHA-256 values. The unit tests repeat this isolated replay.

The unchanged `constructor_implied_do` source is promoted to success in0.46, with a GNU execution oracle. Its independent array-constructor scope is documented in tests/constructor_implied_do; output-counter rules are unchanged.
