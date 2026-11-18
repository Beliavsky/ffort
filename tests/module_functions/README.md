# Independent module-function tests

The fixtures and expected outputs were designed separately from the interpreter
implementation. `manifest.json` specifies the supported programs, static
rejections, and checked runtime policy. The runner invokes the interpreter CLI
and an independent GNU Fortran reference; it does not use an interpreter result
to generate expected values.

Run from the repository root, with absolute executable paths:

```sh
python3 tests/module_functions/test_runner.py
python3 tests/module_functions/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran
```

GNU is compiled with `-std=f2018 -pedantic-errors -fcheck=all -O0`, in a fresh
working directory per fixture so that module files from another test cannot
satisfy a missing USE. A `run` oracle compares execution against independently
specified output, `compile` proves a legal unsupported or policy fixture is
valid Fortran, `reject` requires GNU to reject invalid source, and `skip` makes
no GNU claim. No GNU oracle is claimed for uninitialized values, arithmetic
safety, work-budget exhaustion, or an unresolved external/cyclic linking probe.

Candidate checks require exit 0 for success, 1 for static rejection, and 2 for
runtime failure. Every fixture is also run under `--check`, which must never
produce program output. Static errors must produce no output. Runtime cases
check exactly which earlier completed PRINT records remain, and diagnostic
matching strips the source path so fixture names cannot satisfy the assertion.
Output comparison allows real32 rounding while keeping integer values and text
exact. Ten runner self-tests check these properties.

Coverage includes:

- The requested `twice(2.3)` example, nested/forward and zero-argument calls,
  default INTEGER/REAL/LOGICAL arguments and results, conversions in results,
  multiple positional arguments, aliased actual values, repeated calls,
  local PARAMETER, IF and counted DO, implicit main and IMPLICIT NONE.
- Caller/dummy/result/local isolation, independent same-named functions in
  different modules, USE visibility, ambiguous imports, intrinsic-name
  shadowing, and semicolon-separated scope boundaries.
- Scalar calls used with array elements, assignments, subscripts, sections,
  empty arrays and empty scalar-expansion targets.
- Missing, extra, wrong-type and wrong-rank arguments; declaration errors;
  undeclared or conflicting names; direct and indirect cycles.
- Rejection of mutable module state, function I/O, missing INTENT, optional/
  keyword arguments, implicit result names and SAVE-bearing mutable initializers.
  Original fixtures for later-supported typed headers, procedure calls, RETURN,
  USE ONLY and local arrays retain their source with migrated expectations.
- Uninitialized result/local reset between calls, uninitialized actuals,
  division by zero, integer overflow, atomic PRINT, section-bound failures,
  and a work budget shared by all calls.
- Exact accepted/rejected boundaries at 16/17 arguments and 16/17 modules.
  The historical 64/65-procedure chains now both pass compilation; 64 active
  frames execute, while 65 frames fail safely at the independent runtime-depth cap.
  Current whole-source metadata boundaries are in `../metadata_limits`.

Some `invalid` candidate cases are GNU-valid through implicit typing; their
`baseline` is therefore `compile`. They are rejected by the interpreter's
explicit-declaration contract, not presented as Fortran language errors.
