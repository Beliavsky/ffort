# Configuring array capacity

The default is **1,000,000 elements**. A **10,000,000-element** build is also
verified, but remains opt-in because whole-array assignment can require about
1.4 GiB on the measured debug build. This is a bounded interpreter, not an
unlimited-memory implementation or a security sandbox.

## Change one named constant

In `src/fi_ir.f90`, change only:

```fortran
integer, parameter :: max_array_elements=1000000
```

For a high-memory configuration, use `10000000`, then rebuild all dependent
modules. There is deliberately no mutable process-global runtime setting: a
program's parser, independent frontend validation and execution use the same
compiled policy, including when the reusable API is called repeatedly.

```sh
fpm clean --all
fpm build --profile debug
```

The cap applies to aggregate explicit declarations, live owned storage in each
frame, the shared module storage pool, actual arguments materialized by a call,
array-valued results and the expression-result cache. Rank-two/rank-three arrays
count their product, not their largest dimension. Pointer aliases borrow storage
and do not charge it a second time. Scalars do not count. Empty arrays have zero
storage, but nonempty results inferred from them still obey the cap.

Use a positive default-INTEGER value below `huge(0)`. Extents/products are checked
in int64 before conversion and allocation. Larger settings do not enlarge the
signed-32-bit bound/index model. Values above 10,000,000 have not been measured
or certified by this capacity work.

## Storage and ownership

Arrays are heap-allocated for their actual extents, never reserved at the configured
ceiling. FORALL index scratch also uses the actual validated iteration counts;
a three-element FORALL does not reserve ten million index slots in a high-cap
build. Empty iteration products reserve no index values.

The ordinary tagged value no longer embeds two array descriptors used only by
derived scalars. Instead, an optional allocatable record payload owns the component
values and definition flags. Intrinsic assignment retains deep-copy ownership,
including array copies and replacement by non-record values. Numeric, LOGICAL and
CHARACTER values do not allocate that payload. The internal IR layout changed;
rebuild clients against the new modules rather than mixing old object files.

With GNU Fortran 14.2.0 and the FPM debug flags, including `-fcoarray=single`,
`storage_size(value_t())/8` is **72 bytes**, down from **184 bytes**. Each stored
element also has a four-byte initialization flag. Native compiler flags affect
descriptor size: a standalone build without coarray metadata measured 56 bytes,
which is not the packaged FPM measurement; the old standalone layout was 176 bytes. These are tagged values, not packed
four/eight-byte native numeric arrays. CHARACTER strings and derived payloads
need additional storage.

Assignment and RANDOM_NUMBER stage results before committing. Array actuals,
callee storage, function results and expression caches can retain more copies.
Each region is bounded, but the cap is **not a total-process memory limit**.
Several active frames, modules or large actual/result copies can use substantially
more than one array. Checked array-storage allocations report diagnostics or the
supported ALLOCATE STAT result. These guards do not cover every pre-existing
internal allocation or implicit CHARACTER, derived-payload and argument-copy
allocation; those paths may still terminate on allocation failure. Host
overcommit/OOM behavior cannot be guaranteed by Fortran ALLOCATE STAT. An OS
memory limit bounds process resources but does not turn unchecked allocations
into recoverable interpreter errors; use one for resource-sensitive execution. The verification harness uses an address-space limit before launching
large tests, not an uncontrolled attempt to exhaust host memory.

## Separate limits and the untouched utility source

The default work budget remains 1,000,000 steps. Large traversals need explicit
`--max-steps`, for example 20,000,000 for the one-million-element profile.
Compilation's constant evaluation retains its own work budget. PRINT retains its
65,536-value cap, and source/token/metadata, CHARACTER length/byte, output, call
depth and other limits are unchanged. Increasing one cap does not raise another.

The original 338,883-byte `tests/utilities_slices/source/xutilities.f90` remains
unchanged, SHA-256 `c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
Its fixed `xbig(10**8)` declaration still exceeds both measured configurations.
The default build rejects at `9329:55` before output with the configured
1,000,000-element diagnostic. This work does not rewrite that declaration, add
external-unit READ/CLOSE, or claim full utility-library execution.

## Reproducible checks and observed costs

`tests/array_limits/run_tests.py` derives the cap from the source constant and
checks 30 boundaries: declarations, aggregate/frame/actual storage, assignment,
constructors, parameters, intrinsic results, overflow and independent limits.
A call-copy probe receives an explicit budget so its intended storage rejection
is not hidden behind the unchanged work limit. Historical generated resource
fixtures have been refreshed for the new default; versioned verification reports
remain historical, rather than having their old measurements rewritten.

`test/test_compact_value_storage.f90` checks payload ownership, nested deep-copy
independence, lifetime and release when values become numeric. The complete combined default-cap native suite checks the compact representation,
derived frontend identity, CLASS/defined output, multi-object allocation and
specification-length CHARACTER composition. High-cap validation remains limited
to the separately recorded focused profiles.

On Unix, run the optional, separately bounded high-memory profile:

```sh
python tests/array_limits/profile_capacity.py \
  --candidate /path/to/fortfront-interpreter --gfortran gfortran \
  --limit 1000000 --result capacity-1000000.json
```

Use `--limit 10000000` only with the corresponding rebuilt candidate. Each child
has a 1,600 MiB address-space guard. Failure tests instead use 64 MiB. Deterministic
successful outputs are checked independently with GNU Fortran. Both candidate
and GNU execution must have status zero, the expected output and empty stderr.
Negative probes require the specified nonzero status, expected output and one
source-located named diagnostic. Host runtime-error, backtrace, signal, fatal-error
and internal-compiler-error markers are rejected rather than counted as controlled
interpreter allocation recovery. Lightweight adversarial checks run through
`tests/array_limits/test_runner.py`, without allocating large arrays. Eight probes per
configuration cover storage, staged assignment/reduction, rank three, pointer
aliasing, tiny FORALL, above-cap rejection, allocation failure and STAT recovery.

Observed merged 0.42 Linux x86-64 FPM-debug results (not cross-platform guarantees or uncontended benchmarks).
The default executable has SHA-256 `2161f2469cbd88100459caadc894584b9b9ea2a56c01cb5f77c2c2c5d9a7296d`;
the separately built high-cap executable has SHA-256 `84319b0def98ee0fd57d300824004676ff19cd098e4deafb13d63f8ac8ac4d48`.
Both use the same toolchain and normalized project flags. All implementation and
vendor source bytes match except the single `max_array_elements` literal. Only
the application was built for the high-cap profile; no high-cap all-native pass
is claimed.

| Probe | Elements | Peak RSS (KiB) | Elapsed seconds |
|---|---:|---:|---:|
| Static storage and boundary writes | 1,000,000 | 104,040 | 0.063 |
| Staged assignment and reduction | 1,000,000 | 174,472 | 0.870 |
| Static storage and boundary writes | 10,000,000 | 771,836 | 0.553 |
| Staged assignment and reduction | 10,000,000 | 1,475,228 | 10.293 |
| Pointer alias and boundary write | 10,000,000 | 772,116 | 0.302 |
| Three-element FORALL, 10-million cap | 3 | 39,528 | 0.027 |

Both measured configurations rejected their limit-plus-one declaration with no
program output. With the 64 MiB guard, ordinary array allocation failed cleanly
and ALLOCATE STAT recovered with a nonzero status and an unallocated descriptor.
The one-million default leaves substantially more room for call/result copies
than the high-memory configuration.
