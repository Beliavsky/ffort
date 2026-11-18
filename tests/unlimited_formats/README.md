# Unlimited-repeat literal formats and bare G0

Run from the repository root with fpm/gfortran on PATH:

```
python3 tests/unlimited_formats/test_runner.py
python3 tests/unlimited_formats/check_provenance.py
python3 tests/unlimited_formats/run_tests.py --candidate /absolute/path/to/fortfront-interpreter
fpm test --profile debug --flag '-ffree-line-length-none' --target test_unlimited_formats
```

The manifest records 52 checked source fixtures: 27 successful executions,
20 source rejections, and 5 runtime failures. Positive cases require a silent
`--check`. Formatted output is compared byte-for-byte with GNU and, for structural
cases, independent exact expectations. Ordinary reversion, trailing literals,
zero-sized lists, finite nested groups, intrinsic types, signed zero, actual
REAL4/8 kind, output/value/traversal boundaries, dynamic shape/type validation
and statement atomicity are covered. The native test adds 38 independent
assertions, including malformed runtime IR and exact format capacity boundaries.

The 21 runner self-tests prevent tolerance from hiding spacing/newline/text,
signed-zero, tiny nonzero, integer and nonfinite errors. `demo_log10` alone uses
numeric comparison for its second, originally list-directed statement; its first
formatted line remains byte-exact, and its second line must independently be
0 through 7. The GNU oracle is compiled in strict Fortran 2018 mode with full
runtime checks and floating-point traps. Negative formats that GNU accepts
without diagnosis are not run by the oracle; see each manifest entry.

`demo_erfc.f90` and `demo_log10.f90` are the complete unchanged upstream examples
from urbanjost/M_intrinsics commit fc14233036d910e3678d350efc24609e11475067.
`provenance.json` records their original paths and SHA-256 values, and
`M_INTRINSICS_LICENSE` retains the upstream MIT notice. No wrappers or synthetic
helpers are used. `check_provenance.py` verifies the exact source/license bytes.

The derived-object source boundary reaches the existing missing defined-WRITE
binding diagnostic; direct native validation independently proves G0 rejects
invalid and derived type tags. This is not a claim that the source fixture alone
exercises that runtime guard. See [the supported contract](../../docs/UNLIMITED-FORMATS.md)
for all exclusions and unchanged resource limits.

The historical `unsupported_colon` fixture is now a successful exact-record
regression under the separate colon-format extension; its Fortran bytes are unchanged.

FortFront 0.49 promotes unchanged `unsupported_slash.f90` to success with exact
`1\n\n` records. Its historical filename and all bytes are preserved. No shipped
source generator exists for this row.
