# FortFront 0.56.0 measured verification

The fresh-source, empty-cache Linux GNU Fortran 14.2 debug maintained run passed 11,625 source contracts across 201 suites: 10,865 direct GNU checks, 83 lowered SIMPLE checks and 677 GNU skips, with zero failed contracts. It passed 285 native programs and 397 verifier commands, with 7 separately reported static/shared comparisons and 2,885 unittest-method executions. Direct GNU checks include execution, compile-only and required rejections; they do not imply universal execution equality.

See [measured summary](verification/0.56.0/final-summary.json), [source/output audit](verification/0.56.0/source-audit.json) and [tool preflight](verification/0.56.0/clean-preflight.json).

The new internal-element suite has 51 contracts: 28 GNU executions, 21 compile-only cases and 2 GNU rejections. External-element coverage remains 67 contracts (44/20/3). New native assertions are 106 IR, 37 frontend and 24 producer-PURE checks; assertions are not separate programs.

The separate fresh identity-bound M_intrinsics survey retains 74 ordinary complete passes. All 249 normalized check comparisons and 79 prior deterministic run comparisons match 0.55. Timing-sensitive streams remain separately classified; this survey is not included in maintained-suite totals.

The reduced utilities working copy stops at 3084:47 on an internal READ section target. The untouched original remains blocked at 9329:55 by the array-size cap. Neither full source is claimed to execute successfully.

Final document and three-part archive reconstruction review remain separate from these source measurements.

## Historical delivered 0.55 verification (verbatim)

The following describes 0.55 and earlier checkpoints only.

# FortFront 0.55.0 measured verification

The fresh-source, empty-cache Linux GNU Fortran 14.2 debug run completed successfully. [Measured summary](verification/0.55.0/final-summary.json), [source/output audit](verification/0.55.0/source-audit.json), [tool preflight](verification/0.55.0/clean-preflight.json) and [full verifier log](verification/0.55.0/full-verifier.log) retain current evidence.

## Maintained verification

200 maintained suites and 11,574 source-contract outcomes: 10,814 direct GNU checks, 83 explicitly lowered SIMPLE checks and 677 GNU skips, with zero failed contracts. There are 282 native programs, 7 separately reported static/shared comparisons, 2,825 unittest-method executions and 394 maintained verifier commands. Direct GNU checks include execution, compile-only cases and required compiler rejections; they do not mean universal execution equality. Normal and optimized hooks can repeat unittest methods.

The new READ-element suite contributes 67 source contracts: 44 GNU executions, 20 compile-only cases and 3 measured GNU rejections. Its native test separately checks 447 assertions. These categories are not interchangeable.

## Separate survey and utilities boundaries

The fresh identity-bound M_intrinsics survey checked 249 pinned sources and ran 79 deterministic examples. It retains 74 ordinary complete GNU-agreeing passes with the same classification as 0.54. This is a separately measured run with its own identity and timing, not a new aggregate maintained-test count; its other categories remain separate. See the [survey receipt](verification/0.55.0/reconstructed-m-intrinsics/receipt.json).

The authorized reduced utilities working copy stops at 3000:27, internal READ from a CHARACTER array-element input file. The untouched original remains blocked at 9329:55 by the array-size cap. Neither full source is claimed to execute successfully in FortFront.

## Fresh-output requirement

Run maintained verification from a fresh extraction with a fresh build cache and absent exclusive-output targets. Do not rerun over retained outputs or relax exclusive-output guards. Five historical INQUIRE harness/result, substring and release054-integration receipts are retained under `docs/verification/0.55.0/historical-exclusive-receipts/`, preserving their original relative paths, bytes and modes. Current receipts live only in the companion exports; the corresponding source output paths and READ-element result/raw-evidence targets remain absent in the main ZIP. A stopped run does not certify a successor extraction.

Windows and other unmeasured platforms remain unverified. Actual final ZIP reconstruction is a separate delivery gate.

## Historical 0.54 measured verification

The following 0.54 report is preserved verbatim. Its counts, hashes, platform and survey are historical; they are not fresh 0.55 results.

# FortFront 0.54.0 measured verification

The empty-cache Linux GNU Fortran 14.2 debug run completed successfully. [Full-run receipt](verification/0.54.0/current-evidence/full_verification_receipt.json), [completion gate](verification/0.54.0/completion-gate.json) and [measured summary](verification/0.54.0/final-summary.json) retain the exact commands, source/tool identities and current results.

## Maintained verification

- 199 suites and **11,507 source-contract outcomes**: 10,747 direct GNU checks, 83 explicitly lowered SIMPLE checks and 677 GNU skips. Zero failed contracts. Direct checks include executions, compile-only checks and required compiler rejections; they are not all execution-equality results.
- **281 native programs**, plus 7 separately reported static/shared comparisons. This does not claim every native program ran as the same static and shared binary.
- **2,765 unittest-method executions**. Normal and optimized Python hooks can repeat methods; this is not a count of unique tests.
- **10,566 integer-mask assertions**, separately counted from source outcomes, native programs and unittest methods.
- INQUIRE harness controls: **5,222 poison and 144 genuine controls per mode**, normal and optimized Python. These are synthetic controls, not additional source cases.

The four current suites contain 36 INQUIRE cases, 40 F0 cases, 24 array-element substring cases and 18 integrated compositions. The composition suite retains its original 12 cases and adds 6; the 12 are not counted again. First preview failures, corrections and exact historical expectation migrations remain preserved.

## Source and output preservation

The frozen source input SHA-256 is `4743f8dee5d008631cd3a9dee1b3e7b3ee40337c036fca216597dd7ea5505a35`; the clean CLI SHA-256 before and after verification is `6a48fcda559e6a6d084de4b2d5b7a8e02d14e301c95224b19ace57892c493098`.

The [independent source audit](verification/0.54.0/source-audit.json) checks all 665 compiled-source/vendor assets and all frozen inputs, with exact per-file treatment of 380 changed generated outputs and 1,536 new outside-build artifacts. It binds 545 measured receipts and 597 dynamic exports; these are evidence counts, not additional test cases. Numeric/TRAILZ physical-cache receipts remain distinct from the two transcript-selected F0 JSONs outside the build directory. Compiler caches, generator replays and synthetic mocks are not delivered as production execution receipts. See [dynamic evidence review](verification/0.54.0/dynamic-evidence-review.json).

Relative to delivered 0.53, 13,081 inherited Fortran/include/native/example bodies are unchanged. One additional native body has the separately approved Boolean promotion of the existing `F0.4` expectation; no other part of that body changed. Do not describe all inherited Fortran as byte-identical. All frozen source bodies, manifests and provenance remained unchanged during the clean run.

## Separate reconstructed M_intrinsics survey

The fresh reconstructed-v5 survey uses the same clean CLI/source input and 249 pinned sources. Categories are 74 ordinary complete GNU-agreeing examples, 155 interpreter source rejections, 13 empty placeholders, 2 runtime-domain rejections, 1 environment-sensitive acceptance, 2 independently validated known-GNU-defect cases, 1 runtime-input rejection and 1 step-budget exhaustion. The special categories are not ordinary extra passes. Counts are unchanged from 0.53. See the [independent survey review](verification/0.54.0/reconstructed-survey-delivery-review.json).

The reconstructed harness passed 3,485 pure validation controls under normal and optimized Python. It is not the lost historical 1,110-control harness or the three lost probes, and no recovery or rerun of those lost artifacts is claimed. The survey is separate from the maintained source totals above.

## Utilities and remaining limits

The untouched original utilities source still fails checking at 9329:55, its retained array-size cap. The authorized one-value reduced working copy now reaches 2995:41 and rejects formatted READ into a CHARACTER array element. Its full GNU compile/run passes separately; neither source is claimed to execute completely in FortFront. Current supplemental evidence retains numerical comparisons and known GNU discrepancies without widening tolerances.

The measured platform is Linux GNU Fortran 14.2, official debug plus split DWARF. Source/FPM portability does not imply verified runner portability across arbitrary compilers/platforms. External READ-element support is future work, not part of this checkpoint. [Release scope](RELEASE-0.54.md) states the other bounded exclusions.
