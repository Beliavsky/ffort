# CHARACTER MIN/MAX tests

Run from the repository root:

    python3 tests/character_minmax/test_runner.py
    python3 tests/character_minmax/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran --with-constructors

The 0.46 command above explicitly selects the integrated constructor profile with `--with-constructors`. That profile promotes the unchanged demo_min expected result; the default profile requires its constructor rejection. Both profiles contain 106 cases and name the active profile in results. Original source bytes and hashes never change.

The 54 ordinary successful GNU comparisons use strict Fortran 2018 and exact numeric tokens or exact formatted CHARACTER bytes. The 12 known GNU 14.2 defects are separate outcomes, never counted as GNU agreement. The `oracle-evidence` receipt supplies independent expected array strings, complete expected original output and primary specification support. The 16 compile-only cases cover interpreter bounds and intentional descriptor-only evaluation behavior. Ordinary source rejection remains GNU exit 1; another compiler exit is accepted only by its individually marked, diagnostic-guarded limitation fixture.

Native targets are `test_character_minmax` (273562 assertions) and `test_character_minmax_producer` (18 checks). There are 33 runner self-tests. All original programs are unchanged MIT-licensed M_intrinsics sources at the commit and hashes in upstream.json. See docs/CHARACTER-MINMAX.md for the bounded contract.
