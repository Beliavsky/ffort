# No-argument RANDOM_SEED checks

Run `python3 tests/random_seed_empty/run_tests.py --candidate PATH --gfortran PATH`.
The runner snapshots the candidate executable and uses isolated temporary GNU
builds. It never compares GNU random sequences with the interpreter sequence.

The 25 source cases split into 10 standard syntax/shadow/range execution checks,
4 valid GNU compile-only SIZE/PUT/GET boundaries that the interpreter rejects,
7 invalid-source GNU rejection checks, and 4 interpreter-only checks. Three of
the latter test this processor's deterministic seed policy; the fourth is the
Fortran 2023 SIMPLE rejection, outside the GNU Fortran 2018 oracle mode.

All unsupported and invalid interpreter source cases contain a preceding PRINT
sentinel and must reject without output in both checking and normal execution.
The successful rank-three range case checks elements with scalar loops because
rank-three ANY is outside the existing reduction subset.

`test/test_random_seed_empty.f90` separately checks shared runtime state and
malformed IR, including canonical empty operands, budgets, scope, PURE/SIMPLE
flags, unevaluated KIND, user shadows and harvest-transaction rollback. No host
RNG mutation or full-original source modification is part of these checks.
