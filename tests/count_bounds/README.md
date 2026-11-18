# COUNT-dependent automatic/result bounds

Run `python3 tests/count_bounds/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
The manifest supplies independent output expectations, check/run exit statuses,
and diagnostics. Successful sources are compared with GNU Fortran in strict
F2018 mode. Runtime safety cases and empty undefined operands deliberately do
not use undefined native behavior as an oracle. Unsupported but valid forms are
marked compiler compile-only rather than language-invalid.

The original true_pos_func body is unchanged except LF newline normalization.
Its source path and hashes are recorded in utility-provenance.json. The separate
count_pack_integration suite checks exact positive_int_vec with PACK enabled.
This feature still rejects local/OUT/OPTIONAL mask values, user-defined mask
functions, element/section mask references, and constructors inside dynamic
masks. Full utilities-module support is not claimed.
