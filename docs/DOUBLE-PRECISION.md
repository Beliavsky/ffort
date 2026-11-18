# DOUBLE PRECISION spelling

The bounded source recognizer accepts `DOUBLE PRECISION` and `DOUBLEPRECISION`
as spelling aliases of the existing REAL(8) representation. Neither spelling
introduces a new runtime type, raises precision/resource limits, or permits a
kind selector or star-size suffix.

The aliases work in ordinary scalar/array declarations, module declarations,
PARAMETERs, supported declaration attributes, derived scalar components,
dummy/result declarations and typed function prefixes. Case, whitespace and
continued-token rules are unchanged. Generic resolution and actual/dummy
association require exact REAL(8) kind, as for explicit REAL(8) declarations.
The words DOUBLE, PRECISION and DOUBLEPRECISION remain contextual identifiers
in data, dummy and procedure-name positions; assignment syntax ends a local
declaration section rather than being mistaken for a new type declaration.
An ordinary default-REAL initializer is rounded as default REAL before assignment
conversion to REAL(8); the spelling does not recover decimal precision.

FortFront retains declaration identities and attributes while canonicalizing the
compact type spelling to `double precision`. Strict adapter checks compare the
resolved REAL kind, rank, attributes, signatures and selectors against the IR.
Interface-body declarations/function prefixes are covered as producer evidence
only: the interpreter still excludes external/interface-body procedures.

DOUBLE COMPLEX, REAL(16), DOUBLE PRECISION kind selectors and legacy star-size
syntax are outside the interpreter boundary. The unchanged upstream DPROD demo
uses the compact spelling; its complete execution is recorded in the combined
DPROD feature suite, not claimed by these spelling-only tests.

Validation: `test/test_double_precision.f90` tests producer/adapter/runtime
agreement and corrupted-IR rejection. `tests/double_precision/run_tests.py`
checks a fixed manifest against the CLI and GNU Fortran with `-std=f2018
-pedantic-errors -fcheck=all -O0`, separating compile-only boundary cases from
executed comparisons. Tab separators follow the existing interpreter whitespace
policy; strict GNU rejects that fixture as nonconforming, which the manifest
records explicitly. GNU is an independent oracle, never an execution backend.
