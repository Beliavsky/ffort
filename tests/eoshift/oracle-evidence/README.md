# Isolated GNU14.2 machine-boundary probes

`extreme-shift-results.json` retains exact -O0/-O2 compiler commands, warnings,
exit statuses and stdout/stderr. The five source files are unchanged copies of
the probes and match the recorded source hashes. Standard-model extremes pass;
only min64.f90 crashes. That input uses the extra asymmetric machine minimum,
which GNU explicitly warns is outside the standard symmetric integer range.
The maintained source suite therefore compiles but does not execute that one
GNU probe, and checks the interpreter against independently derived boundary
fill. No other case is allowed to use this classification.

For example: `gfortran -std=f2018 -pedantic-errors -fcheck=all,no-array-temps -O0 min64.f90`.
Do not run this binary as a successful oracle. It is retained only as isolated
compiler/runtime evidence; disable core dumps when reproducing it.
