# Independent release 0.44 composition acceptance

The 29 sources here are independently authored synthetic composition probes.
None is an original utility body or upstream demo. Existing original-source
acceptance and unchanged-byte evidence remain in the dedicated feature suites.
This suite does not claim that the complete xutilities library runs or relax any
existing array, output, expression, format or execution-work limit.

Sixteen successful programs execute independently with GNU and the candidate.
Fifteen require literal stdout byte equality, including spaces, padding, separators
and missing final newlines. The remaining list-directed numeric case requires
exact Decimal values and explicit signed-zero equality. There is no floating-point
tolerance, CHARACTER whitespace normalization or alternative acceptable output.
All successful interpreter checks/runs and GNU executions require empty stderr;
interpreter --check must also have empty stdout.

Nine runtime failures pin both their failure category/diagnostic and the exact
bytes of previously committed nonadvancing output. Four source rejections pin a
specific diagnostic. Eleven cases are GNU compile-only, with a per-case reason:
undefined data, runtime domain failures, interpreter resource policies or a bounded
syntax restriction must not become an unsafe/incorrect execution oracle. Two
invalid-source cases must be rejected by GNU. Compile-only is counted separately
and never represented as an execution agreement.

## Intersections

- Whole scalar runtime formats, named UNIT/FMT controls and nested implied-DOs.
- Internal destination/format aliasing, allocated formats and CHARACTER lengths.
- Pending nonadvancing records across procedure calls, format changes and loops.
- Whole array %LEN on empty/undefined data, absent OPTIONAL KIND metadata,
  deferred lengths and allocation/reallocation.
- Elemental degree arrays assigned inside ordinary loops, rank-two sections,
  implied-DO item order, exact endpoints and REAL8 signed zero.
- KIND of out-of-domain/undefined degree expressions and empty degree arrays.
- Fresh PURE CHARACTER function results containing internal WRITE, with output
  caches refreshed for each implied-DO iteration. PURE remains in the source.
- Late domain/undefined/length failures without partial new output; malformed
  runtime formats checked before undefined loop bounds; zero loop steps.
- Expanded value, empty-body iteration and combined pending-record limits.
- A small explicit work budget fails atomically and prints the exact CLI hint.
- Variable ADVANCE, internal ADVANCE, %LEN assignment and forbidden ordinary
  function module writes retain their precise bounded-domain rejections.

## Running

From any working directory:

```
python3 tests/release044_integration/test_runner.py
python3 tests/release044_integration/run_tests.py --candidate /absolute/fortfront-interpreter --gfortran /absolute/gfortran
```

`verify.sh` takes those two executable paths and runs both commands without
building anything. GNU uses strict F2023 because ACOSD/ASIND/SIND/COSD are F2023
intrinsics. Both checkers use fresh temporary work directories. The runner pins
manifest/source hashes, snapshots the candidate, checks integrity afterward and
records the candidate SHA256, version, compiler flags, complete output and exact
status. Candidate-only and GNU-only runs are explicitly counted as partial.
Forty-four adversarial harness checks guard exact bytes/Decimal/signed zero,
no hidden tolerances, diagnostics, atomic output, bounded budgets and provenance.

## Native merged-library regression

`test/test_release044_composition.f90` combines dynamic format, implied-DO,
SIND, %LEN and KIND in a single verified program. Its 34 checks cover repeatable
immutable execution, seven malformed public-IR copies in both independent
adapter and runtime gates, exact source identity for alternate formats/counters,
and the unchanged reusable-API step diagnostic. It emits no interpreter stdout.
The native test's sole stderr summary is an explicit harness result, not tolerated
interpreter success stderr.

The normal native test discovery includes that file. To link it manually without
rebuilding or modifying the merged library:

```
python3 tests/release044_integration/run_native.py --gfortran /absolute/gfortran --module-dir /absolute/build/module-directory --library /absolute/build/libfortfront-interpreter.a
```

This hook pins the library, source and module bytes before and after, requires a
silent compile, and checks exact native output/status. It writes native-results.json.
No feature-owner library is an acceptable substitute for the merged library.

Provenance: the synthetic sources and combined native test are newly authored for
this release; the runner infrastructure is adapted from certified release043
composition. No historical source, manifest or result is edited. Intentional
changes to these new sources require updating both their hash and the fixed
manifest pin, then repeating applicable verification. GNU expectations are
specified independently; a candidate failure does not change the expected result.
