# LEADZ focused verification

Run the maintained suite (no interpreter build is performed):

```sh
python3 tests/leadz/run_tests.py --candidate "$CLI" \
  --expected-sha256 "$CLI_SHA256" --gfortran "$GFORTRAN" \
  --result final-results.json
python3 tests/leadz/test_contracts.py --evidence tests/leadz/final-results.json
```

The maintained `manifest.json` (also retained as `strict-manifest.json`) binds every source hash, expected output
record and negative diagnostic. There are 59 cases: all 51 initial source bodies,
unchanged, plus eight separately named additions. Candidate outcomes are 32
executions, 22 static rejections and five runtime-safety rejections. GNU outcomes
are 39 executions, 11 compile-only safety/subset cases and nine compile rejections.
The seven initial success expectations that crossed existing subset boundaries
are explicitly mapped in `initial_fixture_mapping`, retain `initial_assumption`,
and have separate GNU output contracts. They do not count as LEADZ executions.

Those seven are `all_positive_bits_32`, `all_positive_bits_64`, `width_64`
(overlong source lines), `allocated_32`, `allocated_64` (rank-three SUM),
`array_function_once`, `kind_suppresses_function` (ordinary-function module writes).
The additions preserve every integer value via standard continuations, print
rank-three elemental values without a reduction, test supported array function
values and unevaluated KIND, and exercise a supported module-derived declaration
before rejecting the direct component operand. No original body was rewritten.
The initial `bounded_component` stops at its unsupported TYPE declaration; it
is not claimed as evidence of a component-expression guard. The additional
`bounded_supported_component` reaches that guard.

`initial-evidence` preserves the first runner, all initial bodies, manifest and
GNU/candidate results. First candidate 1184da74 had 18 failing expectations;
corrected b973c397 fixes the 11 genuine kind-cache failures. Exactly seven initial
subset-crossing assumptions remain failures under the original unchanged runner.
The maintained suite makes that distinction explicit rather than hiding it.
The original GNU/result records remain independent of candidate outputs.

Successful INTEGER/logical records must have exact token spelling and cardinality,
record boundaries and a final newline. Only horizontal list-directed spaces may
vary. Real-looking tokens, nonfinite tokens, extra records, tabs and malformed
integers fail. The original demo has a full 503-byte, seven-record oracle. Check
stdout and successful stderr must be truly empty. Negative cases bind the resolved
source path, line, column, message, phase and exit status; host crash/signal markers
and timeouts fail. `test_contracts.py` exercises these contracts adversarially
against recorded bytes without invoking a compiler or interpreter.

The 59-case corrected-preview run and 3,537 harness checks are focused evidence,
not a full release aggregate. Native `test/test_leadz.f90` has 1,013 independent
metadata/value checks and is compiled centrally against the matching shared library.
