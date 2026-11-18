# RESHAPE regression suite

See [the bounded contract](../../docs/RESHAPE.md). Run `run_tests.py` with
`--candidate` and `--gfortran`. GNU comparisons cover legal inputs only.
`parameter.f90` and `initializers.f90` cover rank-two constant declaration and
PARAMETER initializers, including module/procedure constants, lower bounds,
INTEGER/REAL kinds, LOGICAL, CHARACTER, outer expressions, and empty dimensions.
The generated negatives require axis-by-axis shape agreement and retain the
bounded runtime's SHAPE, ORDER, PAD, overflow and constancy checks.

`demo_unpack_initializers.f90` preserves the declarations through `field` (the two original initializers) from
[M_intrinsics demo_unpack.f90](https://github.com/urbanjost/M_intrinsics/blob/fc14233036d910e3678d350efc24609e11475067/example/demo_unpack.f90)
(commit fc14233036d910e3678d350efc24609e11475067), with a new program wrapper and
PRINT driver. Its MIT notice is in `LICENSE-M_intrinsics`. It is an initializer
slice, not a replay of UNPACK or the original allocatable-character/I/O helper.
`original_vector.f90` replays the original 093_vector procedure unchanged apart
from line-ending normalization; its provenance remains in the utilities suite.

The exact-cap PARAMETER case uses GNU's `-fmax-array-constructor=131072` option
to raise its compile-time folding limit from 65,535; the source remains Fortran
2018 and still uses `-std=f2018 -pedantic-errors -fcheck=all`.

The declaration slice is original source lines 2–15, preserved byte-for-byte.
The runner verifies SHA-256 `e5438c59ea98e1de242c70b5af67b382e183b2b743851d5898e92cdf60cae47b`.
The complete upstream file SHA-256 is `faa6a0b5627147586e69528744f031b8b7c5c686789ea598b7a3ac4fc8b74d89`.
