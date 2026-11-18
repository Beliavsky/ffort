# CHARACTER procedure differential tests

Run `python tests/character_procedures/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.

Every case has an independently specified expected output and explicit category.
The runner checks both `--check` and execution, exact exit classes, empty failure
output, successful stderr and selected diagnostics. GNU always compiles in a
fresh temporary directory, with Fortran 2018, pedantic errors and runtime checks.
Undefined-value/resource/policy cases are compile-only, never claimed as GNU
execution comparisons. `original_concat.f90` embeds the unchanged CRLF bytes of
`concat_char_vec`; `original-bodies.json` records the original body hash.

Legacy expected rejections in the CHARACTER-array, array-result and utilities
slice suites become successful regression cases without modifying those sources.
