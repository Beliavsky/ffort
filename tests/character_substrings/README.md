# Scalar substring checks

Run from the project root:

    python3 tests/character_substrings/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran

The manifest distinguishes executions, compile-only safety cases, source rejects,
and expected runtime diagnostics. The exact original `strip` body is retained
inside `strip.f90`, including CRLF bytes, with provenance checked on every run.
A fresh temporary directory is used for each GNU compilation. Successful output
is compared character-for-character when padding matters. These focused cases
are not a claim that the complete utility source executes.
