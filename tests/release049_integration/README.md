# Independent 0.49 composition tests

The 29 synthetic sources combine grouped initialized/uninitialized derived fields, fixed-length CHARACTER field defaults/copies/lifetimes, runtime stdout-only units, slash/positioning/nonadvancing records, generic REPEAT fallback and matching-user precedence, and LEADZ widths/default result kind/arrays/metadata inquiries. They are independent of the feature-owner corpora. No original utility/demo source is substituted or rewritten.

## Measured outcome

All 29 expectations pass on the immutable combined development preview:

- Candidate SHA-256: `b973c397ab029cc60bc6cc855152b2f7efc7a211e5e4ae97e203890b884d398c`, version 0.49.0, unchanged before/after.
- 21 exact-byte GNU/candidate executions, each with silent checking and empty successful stderr.
- 8 GNU compile-only safety/subset cases: 3 static candidate rejections and 5 runtime rejections, with exact status, source location, diagnostic and committed output.
- 34 adversarial harness tests, including source/generator reproduction and file-only packaging without empty directories.

This is focused composition evidence, not release certification or full utilities support. The runner records version and executable hash before and after. An optional expected hash rejects the wrong executable before case execution.

## Oracle and comparison

GNU Fortran 14.2.0 compiled all 29 silently under `-std=f2018 -pedantic-errors -fcheck=all -ffpe-trap=invalid,zero,overflow -O0`. Twenty-one executed. GNU never executes the undefined/absent data, negative runtime REPEAT count, forbidden non-stdout unit, or unsupported internal-file safety/subset probes. No interpreted/native output file is opened; unexpected files in candidate working directories fail the suite.

Formatted INTEGER records, text case, embedded/trailing spaces, empty records and final newlines compare byte-for-byte. No floating conversion, tolerance, whitespace normalization or integer-token relaxation is enabled. Successful `--check` must return status zero with no output. Both phases of static rejection, and runtime rejection after silent checking, require the exact named source-located diagnostic. Crash/trace/ICE/timeout markers cannot satisfy rejection expectations.

## Preserved first attempts

The initial 28 source bytes and hashes are retained under `oracle-evidence/initial-attempts` and `initial-source-identity.json` and match their maintained counterparts exactly. The first GNU run is preserved in `gnu-first-results.json`: its only mismatch was the independent output expectation for `pending_backward_slash`. GNU produced `ABCDEX\nZ\n` when a new nonadvancing WRITE began with TL2 after the previous statement wrote ABCDE. Expected-output metadata was corrected to that statement-relative left-limit behavior; the source was not rewritten.

The initial candidate observation, unpinned manifest and generator are also retained. All 21 intended successes passed immediately. Literal-known `internal_executed_slash_boundary` rejected at checking, earlier than provisionally expected; the slash owner confirmed static validation is intentional. Its category and empty output were corrected, not its source. The separately named `internal_dynamic_slash_atomic` retains a runtime FORMAT and proves that the runtime error preserves the prior `SAFE\n` record. The eight exact diagnostics were pinned only after observing and reviewing these boundaries. Normal runner execution refuses pending diagnostics.

## Retained boundaries

Direct LEADZ of a derived component remains a source-subset rejection. In 0.50, the unchanged internal WRITE array-element fixture is promoted to check/run success with exact `ABC2    \n` output and independent GNU execution. Its original 0.49 rejection and source bytes remain preserved in the oracle history. Passing that element-file closure does not imply complete utility execution. Executed scalar-internal slash remains unsupported; colon-skipped internal slash is a positive. Invalid/absent runtime units reject before formats/output items, with no native file output fallback. Record-owned storage caps are not stress-tested here; owner native probes cover those. An ordinary allocatable CHARACTER array coexists with a CHARACTER-bearing record, so this suite does not imply a new whole-process CHARACTER heap limit.

## Commands

```
python3 tests/release049_integration/test_runner.py
python3 tests/release049_integration/run_tests.py --gfortran /path/to/gfortran --result gnu-results.json
python3 tests/release049_integration/run_tests.py --candidate /path/to/candidate --expected-sha256 VERIFIED_HASH --gfortran /path/to/gfortran --result results.json
```

The separate additive verifier patch runs the harness and full source suite. No candidate build, native aggregate, shared integration edit or utility source rewrite is part of this artifact.

## 0.50 metadata-only promotion

The historical 0.49 counts above describe the preserved earlier candidate. The
current manifest has 22 executable GNU comparisons and 7 compile-only cases
after promoting only `internal_write_element_boundary`; all 29 source hashes
and `SOURCE-IDENTITY.json` remain identical. No fixture is rewritten.
