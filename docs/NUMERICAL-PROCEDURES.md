# Numerical procedures (introduced in 0.7.0)

The exact user programs are preserved in `examples/black_scholes.f90` and
`examples/module_subroutine.f90`. They execute directly in this Fortran interpreter;
no generated Fortran program or runtime compiler is used.

The Black-Scholes program requires several connected extensions: ISO_FORTRAN_ENV
REAL64, scalar module constants and accessibility, USE ONLY, typed/PURE function
headers, named real kind suffixes, continuation, EXP/LOG/SQRT/ERFC, RETURN,
single-line IF and ERROR STOP, internal subroutines, CHARACTER(LEN=*) INTENT(IN)
dummies, CALL and literal formatted PRINT. These are general supported language
features, not special handling for Black-Scholes source text.

Real32 and real64 values retain their kinds through expressions, assignments and
calls. Actual/dummy kind mismatches are source errors. Module and host constants
are immutable; mutable host/module storage remains outside the supported subset.
Version 0.8.0 adds OUT/INOUT and rank-one assumed-shape arguments; see
[ARGUMENT-ASSOCIATION.md](ARGUMENT-ASSOCIATION.md). Each invocation has fresh local state. All calls and loops
share the instruction/expression budget; recursive cycles require explicit
RECURSIVE on every participant. See [RECURSION.md](RECURSION.md).

PURE prefixes are checked: pure procedures cannot perform I/O or call impure
procedures. All functions remain free of output side effects in this prototype.
ERROR STOP requires a scalar INTEGER or CHARACTER code and produces a checked runtime diagnostic and exit status 2; `--check`
does not execute the stopping branch. RETURN only exits the current procedure;
a function returning before assigning its result is a checked runtime error.

Formats support a comma-separated list of A[width], Iw, Fw.d, Ew.d, ESw.d,
Gw.d, Lw and nX, optionally repeating a descriptor or a bounded parenthesized
group. The descriptor/item type and
count checks happen before execution for statically known counts; runtime-sized
arrays are checked before that statement emits output. Scalar and array items,
PRINT reversion, I0 and Iw.m are supported; see
[FORMATTED-ARRAYS.md](FORMATTED-ARRAYS.md). Nested groups and last-closed-group
reversion are described in [GROUPED-FORMATS.md](GROUPED-FORMATS.md). Arbitrary
external units, format labels and dynamic formats remain unsupported. Explicit widths are
bounded to 1024, precision to 1024 and repeats to 65536. Formatted output is
bounded to 65536 staged characters per statement, including reversion separators.

Later [F0.d output](F0-FORMATS.md) adds a minimal field for finite REAL(4/8)
with precision 0..1024; existing positive-width/G0 paths and staged-record limits
remain unchanged. The preceding original-checkpoint observations are historical.

The financial example is an interpreter acceptance test, not a pricing service
or investment recommendation. Its benchmark and put-call parity assertions are
retained unchanged. Additional tests exercise zero maturity/volatility, positive
and negative rates, deep in/out-of-the-money prices, input rejection and real64
precision. Full recorded evidence is in VERIFICATION.md and the JSON reports.
