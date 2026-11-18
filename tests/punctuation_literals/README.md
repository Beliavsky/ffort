# Punctuation-only CHARACTER tokens

Run `python3 run_tests.py --candidate PATH` and `python3 test_runner.py`.
`generate_cases.py` reproducibly writes the 100 synthetic fixtures and their
hashes/expectations. All passing outputs compare exact bytes and require silent
successful checking. Invalid references are compiled but never executed.

87 cases execute against GNU; 12 malformed cases reject; `structure_actual`
is valid GNU but remains rejected because this subset does not admit CHARACTER
derived components. This existing boundary is separate from delimiter handling.
No existing fixture is rewritten by this suite. Historical expectation changes
and the unchanged composition proof are described in
[../../docs/PUNCTUATION-LITERALS.md](../../docs/PUNCTUATION-LITERALS.md).
