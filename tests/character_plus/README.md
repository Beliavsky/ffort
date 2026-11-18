# CHARACTER plus source suite

See [the feature contract](../../docs/CHARACTER-PLUS.md) for scope, provenance,
producer separation, exact-output requirements and the explicitly scoped GNU O0
alias discrepancy. `manifest.json` fixes each fixture hash, category and reference
compile outcome; `generate_cases.py` reproduces the maintained synthetic fixtures
while preserving the original closure and its raw CRLF module include.

The original three routine bodies are user-supplied test input, not newly licensed
implementation. The module/interfaces/driver are synthetic. `str` binds only the
original `str_int` required by `char_plus_int`; no original helper is replaced.
`check_provenance.py` verifies those embedded bytes and optionally the original
complete source file. `run_tests.py` performs that check before execution.

52 cases cover original scalar/elemental behavior, scalar/array/empty/alias
execution, kind/rank/visibility and interface rejection boundaries, intrinsic
numeric precedence, declared non-CHARACTER results, omitted generic OPTIONAL
arguments, checked ABS overflow, and shape mismatch. The overflow and mismatch
references are compiled, not run. GNU 14.2 accepts an OPTIONAL operator dummy
that the recognizer and adapter deliberately reject; the manifest records the
observed compiler acceptance without treating it as language authorization.

Run `python3 run_tests.py --candidate PATH` and `python3 test_runner.py`.
No output normalization or numeric coercion is used. Results identify the exact
candidate SHA-256. There is no full-library support claim.
