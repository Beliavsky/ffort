# Derived-type and SELECT CASE integration checks

Eighteen independent programs exercise SELECT CASE over derived components,
CHARACTER function results, overloaded logical comparisons and integer differences,
array parameters supplying constructor components, nested selection, INOUT
mutation, character ranges, selection inside a module procedure, exact INTEGER(kind=8) selection above 2^53, signed-64-bit ranges, INTEGER8 parameter caches, and default-kind bounds with a wide selector, and overloaded operator dispatch distinguished by INTEGER kind. The first eight reuse
the priority date module, without depending on special handling of its name.

The common-style runner strictly checks all output and successful check mode,
records source and executable hashes, and compiles and executes every source in
an isolated directory with GNU Fortran. These are integration cases in addition
to each feature's own tests; they are not evidence of complete derived-type or
SELECT CASE language conformance.

Run `python3 run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran`.

Five imported-array regressions preserve exact INTEGER8 values above 2**53 through direct reads, arithmetic, ordinary procedure arguments, constructors and ONLY imports.
