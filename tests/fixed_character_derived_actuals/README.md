# Fixed CHARACTER results with derived actual arguments

This regression suite preserves `tests/release_integration/three_features.f90`
byte-for-byte and compares its complete output `>03>06:0614\n` exactly. The
0.48 constructor length preflight had incorrectly applied an intrinsic-only
metadata rule to the derived passed-object actual of a fixed-length CHARACTER
function. The correction validates derived argument metadata without reading
component values or executing a function merely to learn its declared length.

## Bounded contract

Only declared scalar derived variables, structure constructors and user-function
results may be derived actuals of a function expecting that type. Intrinsic
component references validate their scalar variable base, selector and declared
type/kind. Type identity, scalar rank/shape, component schema/defaults,
procedure/result/actual signatures, type-bound binding identity, cycles and the
existing work budget remain checked. Direct derived `KIND` operands remain
invalid. OPTIONAL derived dummies remain outside the existing parser subset;
OPTIONAL intrinsic actuals exercise the supported non-evaluation path.

## Evidence

Twenty cases pass: sixteen candidate executions and four pinned compile-time
boundaries. GNU executes eighteen cases and rejects the two invalid derived-KIND
programs. All successful CHECK stdout/stderr and run stderr are truly empty;
formatted output is byte-exact. GNU rejection matching requires the intrinsic-type
diagnostic and excludes compiler crashes/fatal failures. Thirty-seven harness
checks and twenty-file generator replay pass. The native public-IR program passes
33 assertions, including 30 invalid type, shape, schema, default, component,
procedure, binding, owner and cycle mutations. Its source is installed under
`test/test_fixed_character_derived_guards.f90`.

All 726 cases across twelve related historical suites pass. No historical Fortran
source body or expectation changed. Eight of the initial twelve cases already
passed certified 0.47; four nested/inquiry cases hit the same pre-existing metadata
boundary there. First-failure evidence is retained and not relabeled as a new
regression. Focused evidence is not a full clean release certificate.

```
python3 tests/fixed_character_derived_actuals/self_test.py
python3 tests/fixed_character_derived_actuals/check_generator.py
python3 tests/fixed_character_derived_actuals/run_tests.py --candidate /path/to/cli --gfortran /path/to/gfortran
```
