# Numeric model inquiries

`EPSILON(X)`, `TINY(X)`, `HUGE(X)` and `RADIX(X)` accept one positional argument
or the keyword `X=`. EPSILON and TINY require REAL(4/8). HUGE and RADIX accept
INTEGER(4/8) or REAL(4/8). All four return a **scalar**, including when X is an
array, empty array, array expression, element or section. EPSILON/TINY/HUGE
preserve X's type and kind. RADIX returns default INTEGER(4).

The model is the same bounded model already used by the interpreter: INTEGER
kinds 4 and 8, and the host `real32`/`real64` kinds mapped to source kinds 4 and
8. EPSILON is the model spacing at one; TINY is the smallest positive **normal
model** number, not a subnormal; HUGE is the largest finite model value (or the
largest positive supported integer); RADIX is the model base. Values come from
Fortran's host inquiry intrinsics, with the existing exact INTEGER(4) bound.
No COMPLEX, unsigned, wider real kinds, small integer kinds, optional KIND
argument or new numerical model is introduced. Derived-component operands are
outside this inquiry extension, including components nested in arithmetic,
constructors, function actuals or subscripts. They reject during checking,
before output. The existing KIND component boundary is not changed. Component-boundary scans
use visiting/visited marks, so cycles fail and shared expression DAGs are
traversed once rather than expanded exponentially.

## Evaluation and composition

As with the existing KIND inquiry, these functions inspect declared metadata.
They do not read X's data, prepare its shape, evaluate its section bounds, or
execute a function used as X. Undefined data, unallocated allocatable arrays,
disassociated supported pointers and absent OPTIONAL dummies are therefore
valid type-model operands. No allocation or pointer-association status is
changed. Calling a function inside an inquiry has no side effects in this
interpreter. Ordinary expression parsing, binding and purity restrictions still
apply to the unevaluated expression; this is not a bypass for unsupported source.

Results can appear in constant initializers and ordinary constant expressions
even when X is not constant. They compose with scalar arithmetic, scalar
expansion, constructors, supported constant KIND selectors, procedure/generic
arguments, and scalar array bounds. Existing rank, shape, recursion, source,
work-budget and declaration restrictions are unchanged.

The syntax/type guard and the FortFront adapter independently check argument
association, numeric type/kind, scalar result shape and exact result type/kind.
The producer's type queries explicitly report scalar inquiry results. Runtime
checks cover count, argument references, type/kind/rank, result metadata, masks
and cycles before using the model. The existing KIND structural walk validates
unevaluated argument trees without loading values. Empty enclosing expressions
also validate inquiry metadata instead of silently accepting malformed IR.

## Verification

`test/test_numeric_model_producer.f90` independently checks scalar producer type/kind/rank and explicit-name shadowing.
`test/test_numeric_model_inquiries.f90` checks scalar values and kinds, adapter
mutations, direct-runtime mutations, nested KIND, cycles and empty-expression
validation. `tests/numeric_model_inquiries/run_tests.py` compares six supported
programs with GNU Fortran and rejects invalid types, argument association and
unsupported kinds. It checks scalars, ranks one through three, zero-size arrays,
undefined section bounds, optional absence, unallocated/disassociated operands,
function non-evaluation, constants, generic selection and FLOOR composition.
REAL comparison uses a relative tolerance of 1e-14 and no absolute tolerance,
so a zero result cannot pass as
TINY; integer output is compared exactly.

The same runner also runs the three preserved M_intrinsics test inputs
under `tests/numeric_model_inquiries/original`: `demo_floor.f90`, `demo_radix.f90` and
`demo_tiny.f90`, records their SHA-256 hashes, and compares candidate execution
with GNU. The source files and upstream MIT license are preserved byte-for-byte, with
`original-provenance.json` checked on each test run. An optional
`--original-dir PATH/example` checks an external copy as well.
The checked upstream revision is `fc14233036d910e3678d350efc24609e11475067`.

Commands:

```
fpm test --profile debug
python3 tests/numeric_model_inquiries/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

Semantic references: GNU Fortran's primary documentation for
[EPSILON](https://gcc.gnu.org/onlinedocs/gfortran/EPSILON.html),
[TINY](https://gcc.gnu.org/onlinedocs/gfortran/TINY.html),
[HUGE](https://gcc.gnu.org/onlinedocs/gfortran/HUGE.html), and
[RADIX](https://gcc.gnu.org/onlinedocs/gfortran/RADIX.html).
The implementation is original glue over host Fortran model inquiries, not a
copy of GNU's intrinsic implementation.
