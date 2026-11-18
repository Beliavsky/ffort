# FINDLOC verification

From the project root:

```sh
python3 tests/findloc/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
fpm test --target test_findloc
```

`run` cases compare with GNU Fortran using Fortran 2018, pedantic errors, full
checks and floating invalid/zero/overflow traps. `policy` cases check documented
interpreter behavior and are not executed as GNU correctness oracles. `reject`
cases must fail both check and execution with source status 1 and no output;
`runtime` cases must pass check mode then fail execution with status 2 and no
partial output. The runner records candidate digest, stages and diagnostics.

The suite covers numeric/LOGICAL/CHARACTER searches, distinct numeric kinds,
exact INTEGER(8) values above 2**53, blank-padded and zero-length CHARACTER values,
nondefault lower bounds, negative sections, DIM/MASK/KIND/BACK and keyword
association, empty shapes, parameters and function composition, stateful scalar
VALUE evaluation, no source reads behind false masks, undeclared data safety,
OPTIONAL VALUE, source-name shadowing and native metadata mutation checks.

`check_original_bodies.py` checks the original compress executable algorithm
against the supplied source, plus a separate fixture preserving the full
original declaration. The historical declaration fixture now passes but its
empty main does not invoke compress. The older executable wrapper retains its
CHARACTER(*) dummy adaptation. Exact full-body execution with the original
LEN(words) dummy is separately verified in `tests/allocatable_character_lengths`.
See `docs/FINDLOC.md` for these distinct scopes. This does not prove the entire
original utilities module runs unchanged.
