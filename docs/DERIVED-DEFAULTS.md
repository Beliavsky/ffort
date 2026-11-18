# Bounded derived-component defaults (introduced in 0.47, extended in 0.49)

The exact reported source is retained as `tests/derived_defaults/cases/exact_user.f90`:
a module-defined `dt` with `real :: y=1000.0`, followed by an anonymous main
that declares `type(dt)::x` and prints `x%y`. It now prints 1000 without a source
rewrite. The prior source guard stopped at `=`; the anonymous main also exposed
an independent producer mixed-unit routing defect corrected by vendor 0097.

## Supported behavior

The existing module-defined, scalar derived type subset supports up to 16 scalar
INTEGER(4/8), REAL(4/8), default LOGICAL or fixed-length default CHARACTER
components. Declarations with `::` may mix initialized and uninitialized entities;
each entity retains its own default root or undefined initial state. Existing
uninitialized declaration syntax remains supported. CHARACTER lengths are
constant integers from 0 through 65536; CHARACTER defaults use supported scalar
constant expressions and normal padding/truncation. Defaults are bounded scalar constant expressions: literals,
visible scalar PARAMETERs, supported unary/binary operations, and these scalar
intrinsics: ABS, INT, REAL, KIND, MIN, MAX, MOD, MODULO, SIGN, SQRT, EXP, LOG,
LOG10, SIN, COS, TAN, NINT, FLOOR, CEILING, LEN, IACHAR, ICHAR, SELECTED_INT_KIND,
SELECTED_REAL_KIND, DIGITS, RADIX, PRECISION, RANGE, HUGE, TINY and EPSILON.
Existing intrinsic type/kind/argument rules still apply. No user procedure call
or array-valued constant expression is admitted. The default expression depth
is limited to 64 and the existing runtime work/allocation limits are unchanged.

Creation defines only components with defaults. Procedure-local records receive
fresh defaults on every invocation, including recursive calls. Derived function
results receive defaults on entry. INTENT(OUT) reinitializes defaulted components
and leaves other components undefined; INTENT(IN/INOUT) preserve supplied values.
Component defaults do not imply SAVE. Explicit component writes and intrinsic
whole-record assignment overwrite prior values without aliasing independent
records. An explicit positional structure-constructor argument overrides its
component's default; trailing omitted arguments require defaults. `dt()` is
supported when every component has a default.

## Independent checks and retained boundaries

IR stores exact default-expression roots, not an unchecked initialized-value
cache. The adapter compares source initializer presence, root expression,
module/PARAMETER declaration identity, type/kind and literal value. Declaration
binding is completed before component expressions are checked. The runtime
independently checks root ranges, cycles, shape/scope, constant-only operands,
component metadata, and conversion/finite/integer-overflow rules. It evaluates
defaults into frame-local values through the existing constant evaluator, then
copies them on record creation. Malformed public IR cannot turn a default into
a user call or array expression.

This is not general derived-type support. Nonconstant-length/nondefault-kind
CHARACTER, array, nested-derived, POINTER and ALLOCATABLE components, derived arrays, type extension, local type
definitions, keyword constructors, and derived PARAMETER construction retain
existing boundaries. Module mutable derived objects and derived SAVE locals are
not added. Whole-record copies/results still require all components defined;
partial-record copies remain a controlled existing runtime rejection even if a
later consumer would read only a defined field. Undefined uninitialized fields
are never silently zeroed. Integer overflow and nonfinite constant results are
rejected, even when a compiler folds such expressions without diagnostics.

Vendor 0097 only routes sources beginning with a real MODULE unit through the
normal unit/statement scanner. It avoids the LF mixed-range detector combining
a main declaration with the next executable statement. It does not discard the
trailing-token guard or rewrite tokens. Explicit and anonymous mains, constructor
forms, and retained trailing-junk rejection are independently checked in STANDARD
and LAZY producer modes. Registry/type-query metadata is unchanged.

## Oracle distinction and reproduction

At the original 0.47 checkpoint, the 47-case focused suite had 29 GNU executions,
13 GNU compile-only cases and 5 GNU
rejections. Two compile-only cases are separately flagged oracle disagreements:
GNU 14.2 returns 0 for an empty ordinary/PURE default-initialized function result,
at both -O0 and -O2, instead of the required default 7. Their source bytes and
observations remain in `oracle-evidence/empty-result-profile-disagreement.json`.
They are checked against an independent expected result and are never counted
as GNU execution agreement. Separate nonempty result bodies agree with GNU.

Default initialization of results and INTENT(OUT)/nonsaved locals on invocation
is described by the primary [IBM language reference](https://www.ibm.com/docs/SSWEZ2_latest/pdf/langref.pdf)
(p. 48) and [NEC language reference](https://www.yukawa.kyoto-u.ac.jp/assets/computer/rental/SX8MAN/g1af06e/chap3.html)
(section 3.12.7.5). The implementation does not change semantics to reproduce the
observed GNU disagreement.

Run `python3 tests/derived_defaults/test_runner.py` and
`python3 tests/derived_defaults/run_tests.py --candidate PATH --gfortran COMPILER`.
Successful check mode is exactly silent. CHARACTER/record bytes are exact;
opt-in numeric records use finite Decimal equality with signed-zero preservation.
Errors require exact source location/message, expected exit status, exact prior
stdout and no crash/traceback markers. Source hashes and regeneration are pinned.
The two new native test programs are picked up by the normal aggregate verifier.

The authoritative feature app uses `fpm build --profile debug`, with recorded
`-g -fcheck=bounds -fcheck=array-temps -fbacktrace` and no extra line-length flag.
An earlier flags-only attempt is preserved as diagnostic-only and excluded from
final validation. The full release aggregate is performed by integration.

## 0.49 extensions and bounded record storage

The original 0.47 evidence above is retained. Current grouped declarations are
covered by [28 focused sources](../tests/derived_mixed/README.md), and fixed
CHARACTER components by [34 focused sources](../tests/character_components/README.md).
CHARACTER fields also retain exact schema type/kind/length checks in the
independent adapter and runtime, staged assignment, and checked incoming records.
Record-owned strings are subject to the named 16 MiB conservative reservation
and separate output staging cap described in that contract. Ordinary CHARACTER
arrays/results are not newly subject to a global heap admission policy.
