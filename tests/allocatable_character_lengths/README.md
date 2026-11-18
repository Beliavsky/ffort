# Explicit specification-length allocatable CHARACTER dummy checks

This additive suite covers mandatory rank-one through rank-three nondeferred
ALLOCATABLE CHARACTER dummies with bounded scalar-INTEGER specification lengths.
The accepted length is frozen per activation after argument association. Every
nondeferred actual must have that exact length, including unallocated and empty
actuals. IN/OUT/INOUT use the existing descriptor and alias rules.

Run from any working directory:

```sh
python3 tests/allocatable_character_lengths/self_test.py
python3 tests/allocatable_character_lengths/run_tests.py \
  --candidate /absolute/path/to/fortfront-interpreter \
  --gfortran /absolute/path/to/gfortran --result results.json
```

The 35-case manifest separately labels 14 successful GNU executions, one safe
expected GNU ERROR STOP, 15 compile-only cases, and five GNU compilation
rejections. Mismatched explicit allocatable lengths, undefined element reads,
and prohibited writable aliases are **never executed with GNU**. GNU compile-only
status does not claim runtime conformance. Two valid-language subset boundaries,
OPTIONAL specification-length dummies and ordinary nonallocatable
specification-length dummies, must be rejected by the candidate before execution.

## Exact original utility provenance

Five fixtures contain the complete untouched `pure subroutine compress` from
`tests/utilities_slices/source/xutilities.f90`, lines 9648–9674. The original body
retains all 27 CRLF endings. Only the wrapper and driver are new. The harness checks
the full original source SHA-256, exact source line range, body SHA-256, and exact
body containment in each fixture. `provenance.json` records both body hash forms.

The three successful drivers cover first-appearance ordering, repetitions, output
self-slice reallocation, repeated calls with preallocated output, different element
widths, empty input, and zero-length elements. Two further drivers verify the
original factors-size ERROR STOP and strict actual-output length agreement. These
are bounded extracted-procedure tests, not full `xutilities.f90` execution.

## Other boundaries

Cases cover unallocated/empty/nonempty IN and OUT descriptors, OUT that leaves its
actual unallocated, nested forwarding, INOUT entry freezing after scalar changes,
self-slice reallocation, recursion with different live activation lengths,
INTEGER(8) arithmetic, bounded PURE specification functions, keyword association
with the output dummy first, rank-two/rank-three results, descriptor-only LEN on
uninitialized/zero-length arrays, and actual element-read rejection.

The CHARACTER limits stay unchanged: 65,536 characters per element and
16,777,216 live CHARACTER array payload bytes. The separately configured array
element cap now defaults to 1,000,000; 10,000,000 is an opt-in rebuild configuration.
The suite checks maximum length on an empty allocation, length overflow,
aggregate STAT recovery, and the element cap even when each element has zero length.

`generate_cap_case.py` derives only the synthetic `element_cap_stat.f90` boundary
from `src/fi_ir.f90:max_array_elements`: the request is cap+1 (1,000,001 by default).
It updates that case's manifest/provenance hashes and leaves original bodies and
all other fixtures unchanged. After changing the configured cap and rebuilding, run:

```sh
python3 tests/allocatable_character_lengths/generate_cap_case.py
python3 tests/allocatable_character_lengths/generate_cap_case.py --check
```

The runner checks source/metadata consistency before any execution. GNU only
compiles this interpreter-policy case; it is not a GNU execution oracle. Six
additional self-tests cover generation at 131072/1000000/10000000, idempotence,
configuration errors and source/metadata drift. Existing `results.json` must be
regenerated against the combined candidate; old 131072-cap evidence is historical.

`test/test_allocatable_character_lengths.f90` contains 181 independent native
checks. Thirty malformed descriptor/expression variants are rejected by the public
gate, adapter, and direct runtime. A separate body-RETURN procedure tests that a
positive cached dummy length cannot bypass dynamic specification validation when
the dummy is never referenced in the body. Missing dynamic text and a different
same-valued source expression have adapter-only identity checks: an assumed-length
IR descriptor remains a legal alternate program, so runtime is not claimed to
reconstruct discarded source text.

`self_test.py` checks output comparison, diagnostics, stage classification,
timeout handling, and byte-exact source provenance, including CRLF drift detection.

## Strict output oracle

Numeric tokens compare exactly with Decimal, including arbitrarily small finite
values, INTEGER(8) precision and signed zero. D/E exponents are equivalent; no
absolute or relative tolerance is applied. Nonfinite tokens are rejected. Text
tokens compare exactly. The explicit `bytes` and `lines` modes preserve all
CHARACTER padding and line endings; subprocess capture does not normalize CRLF
or replace invalid bytes. Successful stderr and check-mode stdout must be truly
empty, and an expected empty execution stream rejects whitespace leakage.
The existing intentional ERROR STOP case alone uses its declared runtime-failure
classification; it does not excuse stderr on successful cases. The harness now
has 25 self-tests including nine adversarial output/capture checks.
