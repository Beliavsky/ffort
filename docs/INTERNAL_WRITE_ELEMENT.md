# Whole CHARACTER array-element internal WRITE

The 0.50 implementation adds an internal file that is one whole default-kind
CHARACTER element of a rank-one, rank-two or rank-three array. The source unit
is retained as a writable designator, not evaluated for its old value. Scalar
INTEGER kind 4/8 subscripts use the existing lower bounds, extents, allocation,
argument association and CHARACTER length descriptors. Fixed, automatic and
supported allocatable/dummy arrays use the existing storage model.

Pointer, PARAMETER and INTENT(IN) targets are rejected. Whole-array files,
sections, vector-subscribed files, substrings and derived-component files are
not added by this feature. Existing scalar internal WRITE remains a separate
path. Explicit PURE array-element WRITE is still outside the producer's narrow
local-scalar-file exemption, even where GNU accepts the Fortran source.

## Addressing and staged commit

Each index is evaluated once. The element-file runtime independently checks
scalar shape, INTEGER tag/kind agreement and index range before computing the
address. It checks target availability without requiring the destination to
be initialized. The logical destination and CHARACTER length are captured;
format/items and the resulting record are staged. Capacity and availability
are checked before committing that one element and its initialization flag.
Other destination elements are not overwritten.

IMPURE function references in the new element-file index, format and output
expression paths are intentionally bounded out. Ordinary functions retain the
existing effect checks. Derived output item roots are rejected, and the actual
staged value tags are checked before rendering, preventing a forged cached
value from invoking a defined-WRITE callback. This is not a blanket rejection
of derived expression subtrees: an intrinsic component subscript and an
ordinary numeric function with a derived actual remain supported. Atomicity
means destination/output staging, not rollback of arbitrary function or random
state effects.

The shared IR validator and standalone runtime independently validate the new
designator/metadata contract. Public-IR tests exercise malformed roots, indices,
kinds, shapes, bounds, missing children, cycles and forged derived values.

## Producer ownership correction

Vendor patch 0108 links completed DO body children to their parent after the
body has been installed, matching the existing factory invariant. It covers
counted, bare and DO-WHILE producer paths without a global-name fallback or
relaxation of independent declaration ownership. At the original 0.50 checkpoint,
DO WHILE was still a source-subset boundary; those producer-only tests did not
imply interpreter support. Current bounded support is described separately in
[DO-WHILE.md](DO-WHILE.md), without widening the PURE element-file restriction.
The unchanged scalar PURE internal-WRITE loop is consequently promoted to
check/run success. The array-element PURE restriction above remains unchanged.

## Measured focused evidence

The immutable corrected preview has SHA-256
`3e9c191de0f548e9dc8fc189c3d579e4fde4dbc2617c0b43170add660ca04a19`.
On that identity, 44 source cases pass exact expectations: 22 GNU/candidate
executions, 16 GNU compile-only boundaries or unsafe runtime cases, and 6
expected GNU source rejections. Successful checks are silent; successful runs
have exact stdout and empty stderr. Negatives require exact source path,
line, column, complete diagnostic, terminal newline, status and phase.
Sixteen adversarial runner tests and the raw-source inventory audit pass.

The central native run passes 185 assertions: 119 original contract checks,
32 index-metadata checks, 10 derived-value guards, and 24 producer-parent checks.
It uses the exact app compilation flags and the shared library made from the
same archive as the corrected preview. This is focused evidence, not release
certification. Preserved earlier outcomes include two independent runtime IR
bypasses and the original loop classification failures; they are not replaced
by the passing reruns.

The `original_integer_labels` closure embeds the exact raw CRLF procedure bodies
from utility lines 1388-1398 and 2366-2378, surrounded only by a new module,
interface and main. Its candidate check, actual execution and independent GNU
execution pass with identical records. The original source SHA-256 remains
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`.
Neither the original utility nor the separately authorized one-byte nmax copy
is modified by this feature. Whole-file checking still reaches later subset
boundaries; passing this closure is not full utility execution.

## Historical regressions and promotions

The unchanged nearby suites passed on the earlier combined preview `eb20721a`:
scalar allocatable CHARACTER 67, CHARACTER procedures 35, OPTIONAL CHARACTER
34, formatted arrays 47, runtime formats 69, internal READ 81, and allocatable
CHARACTER lengths 35. These 368 cases are separate from the 44 focused cases.
A static audit compared 110 historical negatives selected by a DO body or a
binding/unresolved/array-reference diagnostic against the clean 0.49 CLI. Only
the scalar PURE loop changed; the other 109 check statuses and streams matched
exactly. This audit did not execute all 110 programs.

Two metadata-only promotions preserve every fixture byte: the scalar PURE loop
prints `07\n`; the 0.49 composition element-file case prints `ABC2    \n` (four
trailing spaces). On the corrected preview, the complete promoted suites pass
23 and 29 cases respectively with fresh GNU execution, and their harnesses
pass 14 and 35 checks. Generator reproduction preserves all source identities.

## Portable verification

```
python3 tests/internal_write_element/check_original.py
python3 tests/internal_write_element/test_runner.py
python3 tests/internal_write_element/run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran --result results.json
```

The default raw reference is `tests/utilities_slices/source/xutilities.f90`.
See `tests/internal_write_element/NATIVE_HANDOFF.md` for exact-profile native
linking. Do not substitute an old archive or use `fpm test --target` in the
space-constrained shared workspace.
