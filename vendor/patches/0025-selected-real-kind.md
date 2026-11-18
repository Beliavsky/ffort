# SELECTED_REAL_KIND frontend support

Registers SELECTED_REAL_KIND as an intrinsic in strict mode and associates optional
P/R/RADIX positional and keyword arguments when resolving a kind declaration.
The frontend retains its wider kind metadata; the interpreter separately implements
its documented REAL32/REAL64 storage model. No semantic-check fallback is added.

Apply after patch 0024. Focused source, producer/adapter, runtime and GNU-oracle
coverage is in tests/utilities_slices and test/test_selected_real_kind.f90.

The constant-kind selector validator permits the Fortran 2008 zero-argument
SELECTED_REAL_KIND inquiry, while retaining rejection of other empty calls.
Three direct-selector producer regressions verify kind 4 and three negative
producer cases preserve that boundary.
