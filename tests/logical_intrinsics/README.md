# Logical intrinsic regression suite

Run with the interpreter executable and an independent compiler:

```
python tests/logical_intrinsics/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The manifest contains literal expectations rather than generating expectations from
the candidate. GNU checks use `-std=f2018 -pedantic-errors -fcheck=all -O0` in fresh
temporary directories. Runtime-policy cases are explicitly skipped by the GNU
oracle. Large integer output comparisons retain integer precision. Generated
`results.json` records command outcomes and source/candidate hashes.

See `docs/LOGICAL-INTRINSICS.md` for semantics and boundaries.
