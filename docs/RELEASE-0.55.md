# FortFront 0.55.0: formatted READ into CHARACTER elements

This checkpoint adds one complete scalar element of a supported rank-one through rank-three default-CHARACTER array as the target of external literal `(A)` input. Input comes only from explicitly registered units. No OPEN, external WRITE, new format descriptors, general effect relaxation or substring READ target is added. See [the bounded contract](EXTERNAL-READ-ELEMENT.md).

The clean maintained run passed 200 suites and 11,574 source-contract outcomes, 282 native programs and 7 separate static/shared comparisons. The new READ lane has 67 source contracts (44 GNU executions, 20 compile-only cases and 3 GNU rejections) and 447 separately counted native assertions. These are actual clean measurements, distinct from the earlier preview retaining a 0.54 version banner. See [verification](VERIFICATION.md).

The authorized reduced utilities working copy stops at 3000:27, internal READ from a CHARACTER array-element input file. The untouched original remains blocked at 9329:55 by the array-size cap. Neither full source is claimed to execute successfully in FortFront.

The fresh identity-bound M_intrinsics survey checked 249 pinned sources and ran 79 deterministic examples. It retains 74 ordinary complete GNU-agreeing passes with the same classification as 0.54. This is a separately measured run with its own identity and timing, not a new aggregate maintained-test count; its other categories remain separate.

The delivered 0.54 checkpoint and its measured results remain historical, unchanged evidence. First preview failures, corrected test expectations, the interrupted first clean attempt, the second attempt blocked by an inherited exclusive receipt, and the stale harness-count failure found in isolated tail checks are preserved rather than relabeled as passes. The final full clean run is distinct from those earlier attempts. Windows and other unmeasured platforms remain unverified.
