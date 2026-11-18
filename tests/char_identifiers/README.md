# CHAR identifiers and intrinsic shadowing

Run `python3 tests/char_identifiers/test_runner.py`, then
`python3 tests/char_identifiers/run_tests.py --candidate /absolute/path/to/interpreter
--gfortran /absolute/path/to/gfortran` from the repository root.

The 31 contracts comprise 21 strict GNU/candidate executions, eight rejections
and two explicit GNU-only execution boundaries. `--check` success requires no
stdout or stderr. Output comparison preserves text token case/content, normalizes
D/E only in complete numeric tokens, checks integers exactly, and rejects
nonfinite numbers. Whitespace separating list-directed output tokens is ignored.

`original_positions_char_string.f90` preserves the original CRLF bodies of
`positions_char_string` (lines 8812–8822), `true_pos_func` (1552–1564) and
`set_alloc_int_vec` (2538–2558) from the source of record. The module, narrowed
TRUE_POS and SET_ALLOC generic interfaces, and driver are synthetic; no routine
body or dependency is replaced. The driver covers repeated matches, keyword
association, case distinction, no match, empty input, all matches, spaces, and a
multi-character search value. Seven calls exercise dynamic result sizes 0–3.
Source, extracted-body and wrapper hashes are enforced by `check_provenance.py`.
This focused dependency closure is not a complete xutilities module execution.

`use_local_rename` and `use_remote_rename` are valid GNU programs but intentionally
retain the existing interpreter boundary for module-data USE renaming. They do
not count as candidate execution successes. Unrenamed `USE, ONLY: char` works.

Other source fixtures are synthetic. `test/test_char_identifiers.f90` verifies
29 parser/adapter/runtime and producer assertions, including a same-type dummy
binding mutation, array declaration mutation, and malicious reinterpretation of
a CHAR function or generic as the intrinsic. Other reserved names (including
ACHAR) remain unchanged. INTRINSIC/EXTERNAL declarations and procedure dummies
are not added by this patch.
