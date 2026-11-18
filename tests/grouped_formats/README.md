# Grouped format differential suite

From the package root:

    python tests/grouped_formats/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran

Each positive case must pass --check silently, match its independently specified
stdout bytes, and match GNU Fortran compiled with strict Fortran 2018 and runtime
checks. The 18 positive cases cover nested groups, correct last-closed-group
reversion, the assert_le format, quoted punctuation, trailing positioning,
rank-two sections, empty lists, internal records and exact caps. The 21 rejection
cases cover malformed/unsupported formats and static/runtime type, reversion,
size and traversal failures, all without stdout. Negative formats are never run
through GNU. JSON results record source and candidate SHA-256 and both outputs.

These are synthetic focused tests. The assert_le-format fixture uses the exact
format string from the supplied utility source, but does not claim to preserve
that original procedure body. See docs/GROUPED-FORMATS.md for the bounded grammar.

The original unlimited_repeat.f90 source is now promoted unchanged to a passing
case by the later bounded unlimited-format extension. No fixture bytes changed.
See ../unlimited_formats/README.md for the additional grammar and byte tests.

FortFront 0.49 promotes the unchanged `slash_control` slash fixture to a successful
full-record GNU comparison. The filename is retained for provenance; it no longer
means rejection. No shipped source generator exists for this historical row.
