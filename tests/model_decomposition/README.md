# Independent model-decomposition checks

Run `python run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
Either backend can run alone. Run `python test_runner.py` for harness self-tests. The runner verifies exact upstream hashes and the
independent binary-model matrix before testing. Source, executable and manifest
hashes plus compiler versions are recorded in its JSON result.

Three complete upstream examples pass; the complete exponent example remains an
explicit boundary. No original body, wrapper or output statement is substituted.
`UPSTREAM-LICENSE` and `upstream.json` preserve source provenance.

Manifest classifications distinguish GNU execution, compilation-only and rejection.
The oracle-limitations directory retains separately reproduced GNU discrepancies;
these are never accepted by the normal comparator. See `../../docs/MODEL-DECOMPOSITION.md`
for the supported slice and full distinction between finite policy and IEEE support.
