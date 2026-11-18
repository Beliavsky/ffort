# Bounded PURE specification functions

Automatic array bounds and procedure-local/result CHARACTER lengths can call
an earlier-declared, same-file module function when all these conditions hold:

- The function is PURE, SIMPLE, or implicitly PURE ELEMENTAL, and is not declared
  RECURSIVE. It is an ordinary named call, not a generic or type-bound call.
- Its result is scalar INTEGER of kind 4 or 8.
- Every dummy is a mandatory, nonallocatable scalar INTEGER(4/8), INTENT(IN).
- Every actual is a supported scalar integer specification expression, with
  exactly the matching dummy kind. Positional and keyword association use the
  existing call rules. Nested eligible calls and zero-argument calls are allowed.
- The function has a complete declaration before the caller's declaration is
  parsed. Its executable body may call later-declared procedures normally.

This permits the unchanged original utility declaration
`integer :: imat(choose(n,k),k)` in `few_combinations`. Its ELEMENTAL `choose`
function calls the original ELEMENTAL `factorial_long` function. The regression
wrapper includes all three exact bodies, including original CRLF bytes. It
provides the original `long_int` kind value and an independent driver; it does
not claim to execute the complete utilities module.

## Timing and restrictions

The interpreter never evaluates a user function while parsing, in check mode,
or to fabricate a constant cache. These remain runtime specification
expressions even when every actual is a literal. After dummy association, the
ordinary interpreter invokes each function in its own frame, obtains the bound
or length, freezes it, and allocates local/result storage before executing the
caller's body. Changes to an INOUT bound dummy or mutable module data during
that body do not resize those objects. PURE module reads remain permitted;
PURE writes, external I/O and impure calls remain prohibited.

This is not support for user-defined constant expressions. User-function results
cannot be PARAMETER initializers, KIND selectors, or nonconstant main/module
array bounds. Existing type inquiries such as KIND retain their existing rules.
Internal, generic, directly RECURSIVE and optional-formal specification functions,
noninteger/array dummies, mutable local actual values, OPTIONAL actuals and
INTENT(OUT) scalar values stay outside this bounded subset. Some of those forms
are valid Fortran; their compiler-accepted regression cases are explicitly
compile-only policy boundaries, not claimed Fortran errors.

## Independent safety

The shared eligibility check verifies procedure and symbol identities, purity
metadata, exact result/dummy kinds, rank, intent, scope and actual-expression
grammar. The source parser, independent FortFront adapter and runtime each apply
it. Existing independent function-binding, call-graph and purity checks remain
active. CHARACTER lengths are retained as text by the producer, so the adapter
additionally resolves the function in the producer's scope and independently
matches positional/keyword actuals to the guarded expression tree.

The normal shared instruction budget and 64 active-procedure-frame limit also
cover specification calls and their transitive callees. A permitted function
may invoke an explicitly RECURSIVE PURE helper; the normal runtime bound still
applies. Empty arrays do not bypass evaluation or metadata validation. Checked
arithmetic, default-INTEGER index range, 1000000-element frame limits and 65536
CHARACTER-length limits are unchanged. Undefined results are diagnosed. A
failure occurs before the caller's first body statement; no GNU compiler is
used as an execution backend.

## Verification

Run `fpm test --target test_specification_functions` and
`python3 tests/specification_functions/run_tests.py --candidate PATH --gfortran gfortran`.
The focused corpus checks original utility bodies, result arrays, frozen lengths
and bounds, repeated frames, zero/negative extents, kind 8, nested and keyword
calls, module reads, pure transitive calls, overflow, allocation/length limits,
nontermination and depth limits. All compiler processes run in fresh temporary
directories. Infinite and resource-policy examples are compiled, not executed,
by GNU. Native tests mutate purity, binding, argument/result metadata and module
writes, and check shared-budget exhaustion.

## Unresolved generic-call containment

Generic specification calls remain outside this bounded subset. While module
procedure specifications are being parsed, generic specifics have not yet been
resolved to procedure indices. Such calls now receive an explicit unsupported
unresolved-binding diagnostic before any procedure or dummy-list access. This
also applies to a generic named CHAR; the spelling does not add an exception.
Resolved ordinary generic calls in procedure bodies retain their existing behavior.
`tests/generic_spec_guards` verifies clean check/run rejection and unaffected
body calls, including the original release034 composition crash reproducer.
