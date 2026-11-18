# INTEGER bit-intrinsic verification

Run from the repository root with the immutable merged executable:

```
python3 tests/integer_bits/test_runner.py
python3 tests/integer_bits/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran PATH_TO_GFORTRAN --with-slash-formats
```

Without `--with-boz-formats`, the standalone profile expects unchanged
`demo_ior`, `demo_not` and `demo_btest` to reject unsupported formatting.
With `--with-boz-formats`, only IOR/NOT are promoted; that older capability
profile retains BTEST's slash boundary. The new `--with-slash-formats` enables
both B/O/Z and slash support, promotes unchanged BTEST and requires all 24
records byte-exact. IAND/IEOR/BIT_SIZE retain separate DATA/ISO subset boundaries.
All three profiles contain 188 single-outcome cases and results name the profile.
Full original sources and their license are hash-checked before execution.

`manifest.json` has strict expected outputs and GNU classifications. `oracle.py`
contains the independent width-aware oracle; no source generator is shipped in
this historical suite. The maintained files never depend on candidate output. GNU reference binaries are preserved under `oracle-binaries`
when generated locally and are not shipped in the source archive. Exact success
stderr/check-stdout silence is required. Integer comparisons do not pass through
floating-point. `test_runner.py` contains adversarial comparator tests.

The owner-only `results.json` records the standalone executable. Integration
refreshes it with the explicitly enabled merged profile. See
`../../docs/INTEGER-BITS.md` from the repository root for the contract and limits
(the documentation file is `docs/INTEGER-BITS.md`). The full release verifier runs
both the harness and the merged source profile.
