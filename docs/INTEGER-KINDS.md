# INTEGER kinds

INTEGER defaults to kind 4, a checked signed 32-bit value. Kind 8 is a checked signed 64-bit value. Both include their two's-complement minimum: -2147483648 and -9223372036854775808 respectively. No wrapping, saturation or floating-point approximation is used for integer arithmetic or integer comparisons.

## Source forms

- `integer(8)` and `integer(kind=8)`, including supported named scalar INTEGER PARAMETER selectors, declare wide values. Kind 4 remains available explicitly. Other kinds are rejected.
- Integer literal suffixes accept `_4`, `_8` or a previously resolved INTEGER PARAMETER name. Unsuffixed literals remain default kind and must fit its positive literal range. Express the minimum as `-9223372036854775807_8 - 1_8`, not an out-of-range positive literal with unary minus.
- `use, intrinsic :: iso_fortran_env, only: int32, int64` supplies the corresponding kind constants, including local ONLY aliases such as `wide => int64`. See [ISO aliases](ISO-FORTRAN-ENV-ALIASES.md).
- `selected_int_kind(r)` accepts a scalar INTEGER request. Requests at most 9 return 4, requests from 10 through 18 return 8, and requests above 18 return -1. This queries the interpreter's supported kinds, not every kind GNU happens to implement.
- `int(a)` returns kind 4; `int(a,8)`, `int(a,kind=8)` and reordered keywords `int(kind=8,a=a)` select the requested supported constant kind. REAL input truncates toward zero with finite/range checks. Narrowing INTEGER conversion is checked.
- `kind(x)` returns the declared INTEGER kind without evaluating its value.
- A numeric literal kind in a typed FUNCTION header works. A named module-host kind in that header remains unsupported and is diagnosed; use an untyped FUNCTION with a typed result declaration inside its body instead.

## Arithmetic and association

Mixed INTEGER kind arithmetic uses the wider kind; integer exponentiation retains the base kind. Mixed-kind integer comparisons remain exact even above 2^53. An INTEGER mixed with REAL follows the existing REAL promotion and precision rules, not integer exactness rules.

Addition, subtraction, multiplication and exponentiation check representability before overflowing an intermediate. Division truncates toward zero and diagnoses a zero divisor or minimum/-1. Negation and ABS diagnose the minimum value when its positive counterpart cannot be represented. Negative integer powers retain the existing integer result rules. Assignment converts to the target kind and checks narrowing.

`mod(a,p)` follows the dividend sign; `modulo(a,p)` follows the divisor sign. A zero divisor is diagnosed. The integer minimum modulo -1 is zero without executing an overflowing division. MOD, MODULO, MIN and MAX require matching numeric argument kinds.

Procedure dummy arguments require exact type, rank and INTEGER kind, including elemental calls. Numeric assignment conversion does not imply implicit kind conversion at a procedure boundary. Arrays retain their element kinds; constructors require matching kinds, reductions retain element kinds, and numeric products apply numeric promotion.

## Deliberate limits

Array bounds and section-triplet indexing retain the existing bounded default-INTEGER range and array-size/resource limits. INTEGER(kind=8) DO control variables, bounds and steps are unsupported in the integrated release and are rejected rather than executed with unchecked wide loop counts. Wide scalar arithmetic does not expand resource limits.

The explicitly supported two's-complement minimum REAL-to-INTEGER conversion may differ from strict GNU constant-folding diagnostics for the standard's symmetric integer range. The differential suite marks this boundary as an explicit policy skip; it does not run undefined overflowing GNU arithmetic as an oracle.

## Verification

`tests/integer_kinds_independent/run_tests.py` validates --check and execution separately, exact exit statuses and diagnostics, no stdout leakage, exact decimal output, and safe GNU baseline values. It snapshots the candidate executable and records SHA256 hashes, compiler outputs and explicit GNU skips. Its self-tests reject crashes, timeouts and precision-rounded false matches. `test/test_integer_kinds_runtime.f90` separately verifies public-IR arithmetic and overflow guards.

## Mask and logical-shift result kinds

The bounded [MASKL/MASKR/SHIFTR contract](INTEGER-MASKS.md) supports only kinds
4/8. MASKL/MASKR default to kind4 even for a kind8 count; an optional constant
KIND selects 4/8. SHIFTR retains I's kind, while SHIFT may independently use
kind4/8. Counts are range-checked before width-specific operations. These rules
do not add INTEGER(1)/(2) storage or arithmetic, BOZ parsing or new integer
representations. The [ISO availability imports](TRAILZ-ISO-INTEGER-AVAILABILITY.md)
report unavailable INT8/INT16 as -1; they are not small-kind implementations.
