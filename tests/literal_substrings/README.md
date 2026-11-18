# Literal substring source cases

Run `python3 run_tests.py --candidate /absolute/path/to/fortfront-interpreter
--gfortran /absolute/path/to/gfortran`. GNU uses Fortran 2018, pedantic errors,
all runtime checks and floating-point traps. It is an oracle only, not a backend.

The manifest labels each case `run`, `reject`, `runtime`, or `policy`. Safe `run`
cases execute in both implementations and compare outputs; programs also contain
independent assertions. `policy` is never executed by GNU. Rejections may be
valid Fortran outside the bounded subset. Runtime errors are checked for status 2,
a diagnostic and no partial stdout.

All fixtures here are synthetic. `synthetic_digit_formatter.f90` uses the exact
literal substring expression from the original `str_int` body but has a counted
loop and no optional padding. The separate REPEAT/control-flow suite owns the
unchanged original routine and its provenance. See `docs/LITERAL-SUBSTRINGS.md`.

The historical `reject_bracket_token.f90` name is retained, but version 0.43
promotes its unchanged `'['(1:1)` source from rejection to GNU execution through
the separate punctuation-literal parser correction. No source fixture is changed.
