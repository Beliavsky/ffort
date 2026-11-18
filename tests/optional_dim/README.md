# OPTIONAL DIM constraints and intrinsic composition

Run `run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran`.

Direct OPTIONAL dummy DIM actuals are forbidden for ALL, ANY, COUNT, SUM, PRODUCT,
MINVAL, MAXVAL, LBOUND and UBOUND. Parenthesized and arithmetic expressions are
not dummy arguments and remain valid when their values can be evaluated. SIZE
has a different language rule and is not subjected to this rejection.

The suite checks GNU Fortran compile-time agreement, positional/keyword calls,
COUNT reordered slots and KIND wrappers. Three positive composition programs
also exercise optional forwarding, elemental reductions, result type inquiries
on absent values, and shadowing COUNT with an optional user function.
