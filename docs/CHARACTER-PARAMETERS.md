# Inferred-length CHARACTER named constants

`CHARACTER(*), PARAMETER` and `CHARACTER(LEN=*), PARAMETER` infer a
separate default-character length from each entity's constant initializer.
The declaration applies in the main program, module specifications and procedure
specifications. Earlier constants in the same declaration are available to later
initializers; forward/self references and mutable data remain rejected.

```fortran
character(*), parameter :: short = "x", long = "hello", &
                          joined = trim(short)//long, blank = "", nl = achar(10)
character(*), parameter :: words(2) = [character(3) :: "a", "bc"]
character(*), parameter :: empty(0) = [character(7) ::]
```

Lengths include trailing blanks and may be zero. The existing 65,536-character
per-value bound is unchanged. Scalar initializers are evaluated before length
inference, so TRIM's resulting length, rather than its operand length, is used.
Constant TRIM expressions retain folded length metadata, including in untyped
constructors, array concatenation, MERGE, PACK and RESHAPE. Mutable TRIM operands
keep runtime-dependent lengths and do not bypass constant-initializer checks.
Explicit-shape rank-one/two arrays infer their uniform element length; scalar
expansion, named array constants, sections, concatenation, MERGE, PACK and RESHAPE
compose with the existing constant-expression subset. A zero-sized array still
has an element length, taken from the initializer's type metadata, never from a
nonexistent first element. Explicit declared lengths retain their existing
padding/truncation behavior.

## CHAR and ACHAR

`CHAR(I [, KIND])` and `ACHAR(I [, KIND])` accept INTEGER(4/8) scalar or
rank-one/two `I`. They are elemental, return one character per element, and
support positional and keyword arguments, including reversed keyword order.
`KIND` must be a scalar INTEGER constant equal to 1, the supported default
CHARACTER kind. The interpreter supports ASCII codes 0 through 127; other codes
are explicitly rejected rather than wrapped or interpreted using host-specific
extended collating sequences. Invalid constant calls fail during source checking;
invalid runtime values fail before the affected PRINT record is emitted.

## Independent validation and boundaries

The adapter recomputes inferred scalar lengths from the initializer and checks
array expression lengths, declaration attributes and stored constant values.
The source recognizer, adapter and runtime independently check CHAR/ACHAR argument
and result metadata. The runtime also checks values and the character-code range.
Vendor patch 0038 registers these intrinsics with the strict producer, reports
CHARACTER type/kind/elemental rank, and preserves entity-list parsing after
keywords nested inside an initializer. It does not relax semantic checking.

This feature alone adds no substring syntax, general CHARACTER KIND selector, CHARACTER allocation,
legacy `PARAMETER(...)` statement or user-function constant evaluation is added.
Assumed-length nonconstant variables remain limited to existing supported dummy
arguments. Nonconstant initializers, missing initializers, mismatched array
shapes and heterogeneous untyped constructor lengths remain rejected.

`tests/character_parameters` records independent expected outputs and GNU
Fortran checks; native programs separately exercise producer metadata and
adapter/runtime corruption rejection. One zero-sized concatenation length case
records a known GNU14.2 compile defect because it retains the left operand length;
the interpreter follows the sum-of-lengths rule in
[J3/24-007 section10.1.9.3 paragraph4](https://j3-fortran.org/doc/year/24/24-007.pdf#page=184).
The suite README records the concrete difference. The exact original module declarations
from `xutilities.f90` lines 499-504 are retained in a focused source fixture.
The unchanged full original (338,883 bytes, SHA-256
`c257f1b2ee4911e979bb38cf6db044d8593c95e76ab1a7e7a7a769a298698883`)
advanced in 0.25 to the allocatable CHARACTER dummy at 595:45 and in 0.26
to OPTIONAL CHARACTER at 597:54. In 0.27 it reaches a rank-three declaration
at 1829:62, after the earlier OPTIONAL CHARACTER, LEN_TRIM and OPTIONAL numeric-array
gates. Version 0.28 advances to the rank-three ALLOCATABLE declaration at 1987:54. Version 0.29 advances to LOGICAL ALLOCATABLE at 2581:35. Version 0.30 advances to TARGET at 6325:38. Version 0.31 accepts TARGET and stops at POINTER at 6326:16. Version 0.32 adds bounded POINTER views and explicit dummies, then rejects choose(n,k) at 7967:40. Both check and run reject with status 1 and no output. The full original
utility library remains unsupported; this diagnostic advancement does not skip any body.

Later scalar PARAMETER substrings are documented in [CHARACTER-SUBSTRINGS.md](CHARACTER-SUBSTRINGS.md).

## Current 0.35 full-source boundary

The unchanged original now reaches read_vec_data_unit at 9329:55, where the
fixed local xbig(nmax), nmax=10**8, exceeds the configured 1,000,000-element cap.
Check/run both reject before output. No limit is increased and no original
input is reduced to bypass the boundary. External READ/CLOSE remain unsupported.
Earlier line numbers describe feature checkpoints, not whole-library success.
See [INTERNAL-PROCEDURES.md](INTERNAL-PROCEDURES.md) and [VERIFICATION.md](VERIFICATION.md).
