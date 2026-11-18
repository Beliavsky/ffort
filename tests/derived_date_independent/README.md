# Independent month-date program regressions

This suite preserves the owner's priority derived-type source byte for byte in
`user_exact_month_date.f90`, including CRLF line endings. The original source
digest is checked by the runner self-tests. Each generated edge case reuses its
module unchanged, with a small independent driver.

The 73 cases cover the original program, positive/negative/zero offsets, both
arithmetic operand orders in the original source, year rollovers, extreme valid
dates, positive/negative/zero month differences, ordinary derived-value copies,
INOUT copyback, all six comparisons, invalid dates and offsets outside the
supported year range. Date expectations are computed by Python's independent
integer month-index arithmetic. GNU Fortran separately compiles and executes
every case with checking enabled. Neither is an interpreter execution backend.

Eight range guards include maximum/minimum default-integer offsets; conversion
to the wider integer kind must happen before arithmetic so these terminate via
the source's STOP guard, rather than overflow or wrap around.

CHARACTER STOP is normal termination: exit status zero, the expected message on
stderr, no output after STOP, and no partially written output record. Successful
`--check` must produce no output. The harness compares stdout exactly, preserving
formatting and accounting for all output, and stores commands, compiler versions,
source hashes and binary hashes in its JSON evidence.

Run `python3 generate_cases.py`, `python3 test_runner.py`, then
`python3 run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran`.
`--only REGEX` narrows the set; a filter matching no cases is an error.
