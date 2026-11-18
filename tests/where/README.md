# WHERE verification

Run from the project root:

```sh
python3 tests/where/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
fpm test --target test_where
```

The manifest separates GNU `run` differential cases, explicit `policy` expected
results, source `reject` contracts and accepted-source `runtime` failures.
Only `run` programs are compiled/executed by GNU. The GNU oracle uses Fortran
2018, pedantic errors, full checks and floating invalid/zero/overflow traps.
Policy probes with intentionally undefined/unreferenced data are not sent to
GNU or counted as independent semantic agreement.

Coverage includes frozen masks, sequential construct assignments, multiple
masked ELSEWHERE arms, masked division and undefined values, selected failures,
shape/rank mismatches (including all-false and zero-size cases), overlapping and
negative sections, rank-two/reduced-rank sections, scalar expansion, OPTIONAL,
CHARACTER/LOGICAL/numeric kinds, non-reallocation, PURE ELEMENTAL functions,
IF/DO/SELECT/procedure composition and physical continued source locations.
`test_where` separately corrupts instruction chains, scopes, expressions and
assignment targets at both the independent adapter and runtime boundaries.

`check_original_bodies.py` proves that the original utility procedures were not
rewritten. The wrappers use documented harness helpers, not a claim that the
complete utility module runs. See `docs/WHERE.md` for helper restrictions and the
separate existing MERGE/undefined-output limitation.
