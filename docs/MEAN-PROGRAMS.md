# KIND, constructors, initialization and RANDOM_NUMBER (0.16.0)

Both requested programs are included unchanged in `examples/mean_constructor.f90`
and `examples/mean_random.f90`. The first computes and prints 20. The second fills
1,000 REAL64 values and computes their mean using the existing module procedure,
assumed-shape dummy, SUM and SIZE support.

## Type inquiry

KIND accepts one positional X or the X keyword and returns a scalar default
INTEGER. Values are 4 for supported INTEGER/LOGICAL, 1 for CHARACTER, and 4 or 8
for REAL. These kind numbers describe this interpreter's selected kind model;
portable Fortran code should not assume the same numbers on every processor.
KIND inspects declared expression type and does not evaluate data, subscripts,
array section triplets or function bodies. Undefined variables are allowed, and
KIND can appear in a constant expression even when X is not itself constant.
REAL declaration kind selectors accept integer literals, named INTEGER parameters or direct KIND inquiries, including `real(kind=kind(1.0d0))`. Other expression forms inside the selector remain unsupported. Typed function headers retain literal/named parameter selectors only; a direct KIND inquiry belongs in an explicit result declaration. Syntax and type rules inside X still apply. Declaration/recursion/purity rules
otherwise retain this prototype's conservative source restrictions.

## Constructors and declaration initialization

Nonempty `[item,...]` and `(/item,.../)` constructors concatenate scalar and
rank-one INTEGER, REAL or LOGICAL expressions in source order. All items must
have identical type and, for REAL, kind. Numeric assignment conversion occurs
at the target, not between differently typed constructor items. Array items
contribute all their elements in array element order; a zero-sized item
contributes no values. Nested constructors and sections are allowed. Results
always have rank one. Runtime extents are bounded by 1,000,000 elements before
allocation and element evaluation shares the execution work budget.

Nonempty numeric typed constructors, untyped empty constructor syntax and rank-two items are rejected. Bounded constructor implied-DOs are described in [CONSTRUCTOR-IMPLIED-DO.md](CONSTRUCTOR-IMPLIED-DO.md). DIMENSION attributes are supported within
the existing shape restrictions; standalone DIMENSION statements and mutable
initialized procedure locals (implicit SAVE) remain outside the subset.

Main-program arrays can have a scalar constant initializer (expanded to every
element) or a constant expression of matching rank and shape, including a
rank-one constructor. Integer/real assignment conversion and arithmetic checks
are retained. Ordinary variable values, self/forward parameter references and
user-function evaluations are not constant expressions. KIND is the type-only
exception. Initializers are checked during compilation before executable output;
`--check` diagnoses invalid constant arithmetic or shape mismatches.

## RANDOM_NUMBER

RANDOM_NUMBER is reserved by this prototype, so user declarations or procedures with that name are rejected rather than silently shadowed.

One positional or HARVEST keyword actual must be a nonparenthesized writable
REAL(kind=4/8) scalar variable, array element, whole rank-one/rank-two/rank-three array or
section. PARAMETER, INTENT(IN), expressions, non-REAL types and mismatched argument
counts are rejected before execution. Calls are supported in main programs,
impure subroutines, ordinary impure functions and explicitly IMPURE ELEMENTAL
functions; PURE/SIMPLE calls remain rejected. Ordinary impure functions may use the execution-owned RNG stream, but external I/O and module/SAVE/captured-host writes remain rejected; see [ordinary function RNG](RANDOM-FUNCTIONS.md).

The generator is explicitly owned by the interpreter, independent of the host
Fortran compiler's global RNG. Each top-level execution starts at integer state
104729. Each draw computes `state = mod(16807 * state, 2147483647)` with int64
intermediate arithmetic, then divides by 2147483647 in REAL64. REAL32 harvests
round to REAL32 and clamp a rounded 1 to the nearest representable value below
1. Every returned value lies in [0,1); draws are consumed in target element order,
with the first array subscript varying fastest. Nested and ELEMENTAL calls
share one stream. Each new execution repeats it. No-argument RANDOM_SEED resets
that shared stream to 104729; see [RANDOM-SEED.md](RANDOM-SEED.md). RANDOM_SEED
SIZE/PUT/GET arguments and RANDOM_INIT remain unsupported. This reproducible Park-Miller policy is implementation-specific,
not a promise to reproduce GNU's sequence, a high-quality simulation guarantee,
or a cryptographic randomness source.

Target descriptors are resolved once and every index, type, kind, shape and
writeability invariant is validated. All selected output values and RNG state
are staged before a successful whole-call commit. An error leaves the target
and RNG state unchanged; prior completed PRINT side effects cannot be rolled
back. Each draw consumes shared work budget. An empty harvest evaluates its
descriptor but draws nothing and changes nothing. Definition flags are set only
for selected elements; an untouched undefined element remains undefined.

## Evidence and limits

The independent corpus compiles/runs applicable source with GNU Fortran and
uses independently specified value expectations. Random output is checked for
range, variability, preservation of unselected values and deterministic policy,
not equality to GNU's random sequence. Statistical smoke checks are not proof
of distribution quality. Interpreter-only safety and reproducibility checks
are identified separately from GNU conformance checks. Native tests exercise
malformed IR and resource failures. See `docs/VERIFICATION.md` for final counts.

Version 0.18.0 adds fixed-length CHARACTER constructors, including typed empty forms,
under the separate [CHARACTER array contract](CHARACTER-ARRAYS.md).

Array PARAMETER declarations were added in 0.17.0; see [SELECT-CASE.md](SELECT-CASE.md).
