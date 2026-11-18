# Unresolved generic specification-call guard

Run `python3 tests/generic_spec_guards/test_runner.py` and
`python3 tests/generic_spec_guards/run_tests.py --candidate PATH --gfortran gfortran`.
The fresh official debug interpreter is exercised through both `--check` and run.
Every boundary requires exit 1, no stdout and the explicit diagnostic, not a
runtime bounds failure or traceback. Every successful check must be silent.

The 15 cases contain:

- Nine GNU-executed specification-call boundaries: array bounds, CHARACTER
  lengths, an unresolved specific declared later, zero arguments, keyword
  arguments, CHAR/COUNT/nonintrinsic generic names, and the exact release034
  composition crash reproducer `char_generic_specification.f90`.
- Five GNU/candidate execution controls for ordinary generic body calls,
  overload resolution, zero/keyword arguments and supported direct-specific
  PURE specification functions.
- One GNU compile-rejection case: GNU 14 treats the LEN-only generic CHAR
  spelling in `char_character_length` as returning CHARACTER and rejects it.
  It remains a clean candidate rejection test, not a GNU execution agreement.

Source hashes are checked before execution. Output comparisons preserve exact
integer/text tokens while ignoring list-directed separating whitespace. Tests
print no floating-point values. No prior source fixture is modified.

This is a bounded safety fix, not generic specification-function support.
During module specification parsing, generic entries may have specific names
but zero procedure indices because resolution happens after the specifications.
The selector now checks the generic ID, specific procedure index and allocated
dummy list before accessing them. Normal resolved body-call dispatch is unchanged.
