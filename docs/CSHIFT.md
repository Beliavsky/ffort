# Bounded CSHIFT transformation

`CSHIFT(ARRAY, SHIFT [, DIM])` circularly shifts rank-one or rank-two arrays.
Positive shifts rotate toward lower indices: `[1,2,3]` shifted by one becomes
`[2,3,1]`. Negative shifts rotate the other way. DIM defaults to one. See the
[GNU intrinsic reference](https://gcc.gnu.org/onlinedocs/gfortran/CSHIFT.html). The result preserves ARRAY's type,
kind, extents and fixed CHARACTER length, with expression lower bounds of one.

The supported intrinsic element types are INTEGER(4/8), REAL(4/8), default
LOGICAL and default fixed-length CHARACTER. SHIFT is INTEGER(4/8), either scalar
or, for rank-two ARRAY, rank one with the shape of ARRAY after removing DIM.
Each SHIFT element controls the corresponding independent line. Scalar
INTEGER(4/8) DIM must be between one and ARRAY's rank. Standard keyword
association, including reordered ARRAY/SHIFT/DIM, is supported. An explicit
user procedure named CSHIFT shadows the intrinsic. Scalar and array variables,
function result names and generic interfaces also retain the ordinary name-
resolution rules; CSHIFT is not a reserved identifier.

Dynamic descriptors, nonunit bounds, reversed and strided sections, allocatable
arrays, assumed-shape dummies and supported function results are handled using
actual extents. Scalar and vector shifts are reduced modulo the selected extent;
the smallest INTEGER(8) value does not require negation. One-element lines are
unchanged and zero extents produce empty results without modulo by zero.

Evaluation stages the complete result before assignment, so self-assignment and
SHIFT sections aliasing ARRAY use snapshots. Scalar SHIFT and each vector SHIFT
entry are evaluated and frozen once. Function array results and scalar function
values in ARRAY expressions are materialized according to the established
expression rules. Ordinary and recursive source functions may perform supported
RANDOM_NUMBER effects but not external writes or I/O. WHERE and FORALL retain
their PURE-function restrictions. KIND inquires about the result type without
evaluating ARRAY, SHIFT or DIM.

An empty result is not a blanket suppression of its arguments: SHIFT entries are
still frozen and DIM is validated. Obtaining a source function's descriptor can
execute that function even if it returns an empty array. A direct OPTIONAL DIM
dummy is rejected. A parenthesized present OPTIONAL DIM expression is evaluated;
an absent optional value fails safely when referenced.

## Bounds and limitations

Rank three, unsupported element kinds/types, malformed keyword association,
invalid DIM and inconsistent SHIFT rank/shape are rejected. Static defects fail
checking; descriptor-dependent defects fail execution. Undefined values, absent
referenced optional values and unallocated referenced arrays fail safely.

CSHIFT shares the expression/instruction budget. Its staged result and existing
expression result caches together may contain at most 1000000 elements. Fixed
CHARACTER result bytes plus all allocated CHARACTER expression-cache strings may
total at most 16777216 bytes. Ordinary declared ARRAY storage does not count as
an expression cache. The frozen INTEGER SHIFT sidecar is bounded separately by
its validated shape. Failed output expressions do not leak partially assembled
records; previously completed records remain visible.

## Whole unchanged upstream example

`tests/cshift/demo_cshift.f90` is the complete, byte-identical
`example/demo_cshift.f90` from M_intrinsics commit
`fc14233036d910e3678d350efc24609e11475067`. Its 857 bytes have SHA-256
`86868f08e1dc9d4b533e4b170734d02d6006642397486ce4160420b08eaf2fbd`.
The unchanged upstream MIT notice is in `tests/cshift/UPSTREAM_LICENSE`.
The file contains both the original rank-one demonstrations and rank-two
array-valued SHIFT/DIM demonstration. No program body, declaration, formatting,
comment or output was rewritten. The maintained generator never rewrites this
file and verifies its pinned identity before generating other fixtures.

## Reproducible verification

From the repository root:

```sh
python tests/cshift/test_runner.py
python tests/cshift/run_tests.py --candidate /absolute/path/to/fortfront \
  --gfortran /absolute/path/to/gfortran --result results.json
```

The suite has 90 cases: 41 safe GNU executions, 30 GNU compile-only boundary or
interpreter-policy cases, and 19 expected GNU compile rejections. GNU uses
`-std=f2018 -pedantic-errors -fcheck=all -O0` in a fresh temporary directory per
case. GNU is an independent oracle, never an interpreter execution backend.
GNU14 can reject materialization of valid empty rank-two CSHIFT results under
`-fcheck=all`; the explicit empty-assignment invariant is compile-only for GNU.
SIZE-only empty checks are separate and do not establish materialization behavior.
Undefined, unallocated, absent-optional, intentionally failing and resource-policy
inputs are not executed by GNU. RNG checks use invariants, not identical random
streams. Independent expected values are asserted before cross-tool agreement is
accepted.

The runner requires exact check/run exit categories, diagnostics for failures,
no checking stdout, no unexpected success diagnostics, and no leaked failure
output. Integer output tokens are compared exactly without floating conversion.
Real numeric tokens use exact decimal values with D/E exponent normalization and
explicit signed-zero distinction. No absolute or relative tolerance is allowed:
CSHIFT permutes values and must not erase tiny values or change zero signs. This
output check does not claim access to unprinted representation bits. The focused
REAL fixtures also assert permutation values directly before printing PASS.
Eleven runner self-tests exercise tiny-value loss, signed zeros, adjacent large
integers and decimal values, equivalent D/E notation, text mismatches, bad
status/output, whitespace leaks, nonfinite values, completed-record preservation,
unsafe GNU mode rejection, timeout/tool failure handling, full-original identity
and byte-for-byte generator replay.
Reports pin the manifest, every selected source, executable identities, tool
versions, compiler flags and UTC execution time.

`generate_cases.py` regenerates the maintained fixtures and manifest. Verification
replays it in an isolated directory and never rewrites inputs under test.
