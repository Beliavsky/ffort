# Bounded allocation ERRMSG

ALLOCATE and DEALLOCATE accept STAT and ERRMSG in either order, with
case-insensitive option names. STAT remains a whole writable local scalar
INTEGER of kind 4 or 8. ERRMSG is a whole writable local scalar default
CHARACTER with fixed or assumed length, including an already allocated
fixed-length scalar allocatable. Length zero is supported. Substrings, array
elements, deferred-length messages, read-only variables and unallocated
allocatable message storage are rejected by this slice.

On success STAT becomes zero and ERRMSG's value and definedness remain
unchanged. On allocation/deallocation failure, a processor-defined nonzero
STAT and explanatory message are produced. Message assignment truncates or
blank-pads into existing storage. ERRMSG without STAT does not recover from
an error: successful statements are allowed, but allocation errors terminate.

Descriptor/effect validation precedes allocation changes. Controls cannot
alias an allocation object, each other, or active DO counters. With ERRMSG,
bounds and CHARACTER type parameters must be independent of both status
variables and cannot call user functions. Existing multi-object validation
also excludes references to allocation-list objects. The implementation
executes objects left-to-right and stops at the first allocation error:
completed prefix changes remain, an unsuccessful object retains its prior
allocation, and remaining objects are untouched. This is a documented
processor choice, not a portable promise about all Fortran processors.

## Standards and oracle scope

The F2018 interpretation draft [18-007r1](https://j3-fortran.org/doc/year/18/18-007r1.pdf),
sections 9.7.1, 9.7.3-9.7.5, describes object/control independence and error
handling. The F2023 draft [23-007r1](https://j3-fortran.org/doc/year/23/23-007r1.pdf)
changes ERRMSG definition to intrinsic assignment, affecting deferred-length
allocation/reallocation. This implementation deliberately rejects all
such deferred-length ERRMSG objects rather than conflating F2018/GNU14
behavior with the newer rule. Error text and numeric nonzero statuses are
processor dependent and are not compared byte-for-byte with GNU.

## Verification

The focused suite contains 37 cases, including the unchanged complete
M_intrinsics demo_allocated, success/undefinedness, padding/truncation, zero
length, fixed allocatable and assumed-length outputs, partial multi-object
failures, mixed-case controls, and invalid/unsupported storage forms.
Candidate results all pass. GNU checks comprise 22 successful executions,
two expected runtime error terminations, five compile-only boundaries and
six compile rejections; two undefined/unallocated-storage safety cases have
no GNU execution claim. The direct native test performs 244 parser,
independent-producer/adapter, runtime and malformed-IR checks. The runner has
29 adversarial self-tests and requires byte-empty successful stderr/check
stdout and empty output wherever the expectation is empty.

Run `python3 tests/allocation_errmsg/test_runner.py`, then
`python3 tests/allocation_errmsg/run_tests.py --candidate EXE --gfortran FC`.
GNU oracle build files are retained in a fresh temporary directory by default
(or under `--artifacts DIR`) and are never used to execute interpreted source.
