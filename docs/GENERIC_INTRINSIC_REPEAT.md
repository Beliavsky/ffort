# Bounded generic/intrinsic REPEAT coexistence

## Status

Prepared against the implementation-frozen FortFront 0.48 r2 snapshot and tested
in the combined 0.49 preview. Immutable executable SHA-256:
`1184da7445c3eed3b680d0429e24a4cd2125ed317622f2a337f81f71bc200130`.
Both the initial and exact-diagnostic-hardened 39-case runs pass. Central
integration reports all 23 native producer/adapter assertions passing against
the matching combined library. These focused results are not full release
certification or successful execution of the complete utilities program.

## Bounded behavior

A named function generic called `repeat` extends intrinsic REPEAT. A matching user specific wins, including a specific with the intrinsic signature and STRING/NCOPIES keyword names. Only when there is no matching specific can a function reference fall back to intrinsic REPEAT. Ambiguity, CALL statements, ordinary procedures, data objects, and EXTERNAL declarations must not gain fallback merely because their name is `repeat`.

Intrinsic fallback still requires exactly two correctly associated arguments: scalar default-kind CHARACTER STRING and scalar INTEGER NCOPIES. Existing positional/keyword, rank, type, negative-count, and bounded result-length rules remain in force. This extension changes neither the IR representation nor the runtime algorithm. The adapter independently recovers the source generic and verifies that no user specific matched; forged intrinsic IR cannot override a matching user generic.

This narrow extension does not extend every intrinsic name or support subroutine generics extending intrinsic REPEAT. GNU accepts the latter example, so that test is explicitly a supported-language boundary, not a claim that the program violates Fortran. EXTERNAL remains a separately documented unsupported declaration. A negative variable NCOPIES is compiled but not executed by GNU; it is an interpreter runtime diagnostic test, not a portable output comparison.

## Utilities source preservation

`original_repeat_and_str_int.f90` supplies a small module/interface/main harness around the exact raw CRLF procedure bodies at original lines 1041–1048 (`repeat_char`) and 2096–2118 (`str_int`). The original file and bodies are not edited. SHA-256 values and ranges are in `manifest.json`. This verifies the original line-2114 intrinsic call in a small dependency closure, not the entire utilities module or main program.

## Evidence and pending verification

GNU Fortran 14.2.0: 39/39 explicit expectations passed with `-std=f2018 -pedantic-errors -O0 -fcheck=all -ffree-line-length-none`: 24 executed successes, 3 compile-only cases, and 12 expected source rejections. The exact-body utility closure prints `00042`, `xxx`, `q`, `q` on separate lines. Thirteen Python runner unit tests pass. The runner distinguishes --check from actual execution, requires exact successful output and empty stderr, checks exact path, line, column, full diagnostic, status and phase for failures, and records the candidate executable hash.

The native test has 23 producer/adapter assertions, including malformed IR and
attempted bypass of matching-user precedence. Central integration compiled and
ran it by directly linking against the current combined library, without FPM
building the entire test set. At the 0.49 checkpoint the full adapted utility
reached the array-element internal WRITE boundary at 2376:11. The bounded 0.50
additions advanced that unchanged working source to rank-one CHARACTER gathering
at 2493:24, a historical parser rejection rather than full-program success. The
bounded 0.52 CHARACTER gather and bare read-only actual additions advanced it
to rank-one INTEGER gathering at 2678:36. The untouched original still stops at
the configured array limit at 9329:55.
See [the current utility boundary](UTILITIES.md).

Baseline negative controls on the preceding runtime-unit draft rejected both
the simple positional fixture and the exact utility closure with
`No matching specific procedure for generic repeat` before runtime. The original
first combined outcome files remain unchanged alongside the hardened results.

## Design references

IBM XL Fortran documents extension/redefinition of intrinsic generics, including user-specific precedence: https://www.ibm.com/docs/en/xl-fortran-linux/16.1.0?topic=blocks-extending-intrinsic-procedures-generic-interface . GNU oracle records are authoritative only for the tested fixtures, not a substitute for full standards conformance.

## Handoff

`core.patch` contains the three implementation-file changes against the frozen 0.48 r2 source. `additions.patch` contains focused tests, this document, and vendor replay patch 0104. Apply both at the repository root. The vendor replay patch has vendor-root-relative paths and is not to be reapplied to an already patched vendor tree. The focused runner and native test are ready for the central integration verifier; aggregate release certification remains separate.

## numeric-gather progression

Historical 0.53 checkpoint: The 0.53 numeric rank-one extension advances the byte-preserved adapted working source to 2992:1, `INQUIRE`. This is still a source-stage rejection, not interpreted whole-program execution. The untouched original retains its 9329:55 resource-cap rejection. INQUIRE is excluded from this checkpoint; no file-access or ordinary-function effect policy is relaxed. REPEAT resolution and matching-user precedence are unchanged.

## Current bounded input-name inquiry

The focused 0.54 composition adds only [registered input NAME inquiry](INQUIRE_NAME.md). The byte-preserved adapted working source now stops at 2995:41 on external READ to a CHARACTER array element; the untouched original still stops at 9329:55 under the unchanged array cap. Both remain pre-execution source rejections. See the [working-source evidence](../tests/utilities_working/README.md). READ-element support remains outside this checkpoint, and no host-unit discovery, general file access, writable-actual or ordinary-function effect relaxation is implied.
