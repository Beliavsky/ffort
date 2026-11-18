# Independent REPEAT checks

Run `python run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
Either backend can also be selected alone. Expected outputs are hand specified;
`blanks_keywords` compares exact bytes (including internal and trailing blanks).
The manifest explicitly distinguishes GNU run, compile-only, reject and skip.
Never change unsafe/undefined cases to GNU execution just to obtain an oracle.
See `../../docs/REPEAT-INTRINSIC.md` for the bounded contract and native mutation tests.

`run_original.py` independently verifies the supplied xutilities source hash and
original `str_int` body lines 2096–2118, including its unchanged CRLF bytes.
It then checks ten exact formatted outputs against explicit expected answers.
Run with `--gfortran PATH` and, once all three features are merged, `--candidate PATH`.
The original routine also requires literal substring reads and bare DO. The
standalone REPEAT tree's documented rejection is recorded with
`--expect-blocker 'DO requires a declared INTEGER scalar'`, never as a passing
candidate execution. `original-isolated-results.json` records that distinction.

The integrated 0.31 verifier supplies both --candidate and --gfortran and reruns
the unchanged original body successfully. original-results.json is current
combined evidence; original-isolated-results.json is historical feature-only
evidence, not the current release outcome.
