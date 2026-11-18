# Independent 0.45 cross-feature composition

This is a synthetic integration suite, not a rewritten utility routine or an
upstream demo. No original library source is changed or claimed complete.

```sh
python3 tests/release045_integration/test_runner.py
python3 tests/release045_integration/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
```

The 27 deterministic sources cover process-query context, allocated CHARACTER
outputs, explicit external READ, mixed CHARACTER/numeric internal READ,
quoted/repeated/null/slash tokens, rank-three CHARACTER and lexical operations,
all four LGE/LGT/LLE/LLT comparisons, TRANSPOSE alias/reallocation, NORM2/DIM,
empty positive zero, negative zero, existing output implied-DO and T/TL/TR.
Nonadvancing suffixes are tested through nested calls, successful continuation
and failures. Six runtime failures require exact preserved output plus the
specific diagnostic and its exact source line/column. No cap is raised.

Twenty cases execute under both candidate and GNU. Eighteen use byte-exact
CHARACTER/record comparisons; two numeric-only output records use exact Decimal
values with signed-zero preservation. Record counts/endings remain exact, and
integers never pass through binary floating point. There is no tolerance, case
folding, blanket whitespace normalization or nonfinite acceptance.

The six runtime-policy/undefined-data cases and one known static boundary are
GNU compile-only and never executed by the final runner. The preserved
`character_cube_lexical_count.f90` is valid GNU source but uses COUNT on rank
three, beyond the existing rank-one/rank-two COUNT contract. Its candidate check
and run must both reject at 11:32 with the named diagnostic. A separately named
`character_cube_lexical_position_output` case tests the supported rank-three
READ/LGE/output path. The initially observed GNU COUNT output was `3 FTTT`;
this observation is not reported as candidate execution agreement.

## Controlled input and process identity

All sources and input payloads are hash-pinned. Each run creates fresh regular
files named `fort.27`/`fort.28` in a temporary directory. Candidate commands receive
only explicit `--input UNIT=PATH` bindings to these files. GNU uses its ordinary
implicit unit-file association, but those filenames are precreated from the
same pinned bytes, never from user/host files. They are checked unchanged after
execution. Unbound-input cases have no binding and are not run under GNU. Stdin
is closed for both processes. The non-ASCII input fixture contains an intentional
single byte C8 and is a candidate safety-boundary case, not a text decoding test.

GNU is invoked with Python's separate executable parameter and the exact source
filename as argv0. This matches the interpreter's logical argument-zero contract,
without rewriting the source or leaking interpreter flags as program arguments.
The allocated-name/input case verifies its filename suffix and would fail if the
reference instead saw the oracle executable name. Cwd observations are tested
through invariant output rather than unstable absolute-path snapshots. GETCWD
has its explicit GNU-extension flag; all other sources compile in strict Fortran
2018 mode with bounds/runtime checks and floating exceptions enabled.

The runner pins the candidate hash before and after the suite. Twenty-six
adversarial harness tests cover exact text, whitespace and records; Decimal
precision, tiny/nonzero and signed-zero distinctions; source-located diagnostics;
stages/status/atomicity; crash markers; compile-only oracles; input-binding
validation; and byte-exact generator reproduction. The final clean aggregate
remains the release integrator's responsibility.
