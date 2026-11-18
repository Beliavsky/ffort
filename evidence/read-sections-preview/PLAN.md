# Interpreter internal list READ section targets

User-approved scope: rank-one array section destinations for internal list-directed READ, including variable bounds and strides, IOSTAT/failure behavior and GNU differential tests. Baseline is delivered array-intrinsics preview SHA256 ab60ca4123cb81b59bd0f1c51c535f49eafbdd15b20ec73a58105162c4ecd743. Unfinished typed-growth scratch is explicitly excluded.

Retain existing INTEGER4/8, REAL4/8, default CHARACTER target types; no LOGICAL/complex, vectors, rank2 sections, external READ or general file I/O expansion. Validate and freeze all writable descriptors/offsets before transfer. Preserve existing null/slash behavior and error-definedness contract; unaffected array elements stay unchanged/defined. Conservative target-/IOSTAT-dependent bound and same-array repeated-target exclusions must be explicit.

Benchmark: tests/utilities_working/xutilities-nmax-100000.f90, authorized prior single-digit nmax adaptation, otherwise unchanged. Preserve hash. Run candidate --check SOURCE and candidate --max-steps100000000 SOURCE. Baseline gate3084:47 xread(:i), next3087. Fresh evidence, not stale historical run_tests.py prose, determines next blocker.

Author implementation/tests, independent GNU semantics/oracles/lifecycle, native malformed descriptor/mutation tests, separate unchanged utility gate. Full focused/native regression after freeze and complete-source package/extraction audit before delivery. Windows untested, no full maintained certification claim.
