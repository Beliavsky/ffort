# Bounded ACOSD, ASIND, SIND and COSD

Each name accepts exactly one REAL(4) or REAL(8) X argument, positional or keyword.
The result preserves kind and scalar/rank-one/rank-two/rank-three shape. Typed
empty arrays, array assignments and supported sections work. Names remain
nonreserved and ordinary source declarations/procedures/generics retain priority.
No COMPLEX, wider REAL kind, specific-name alias, KIND argument or new I/O
format descriptor is added.

Evaluated arguments must be finite. ACOSD/ASIND additionally require -1 <= X <= 1.
KIND validates the expression structure but does not evaluate its data or call a
user procedure. Runtime and adapter guards independently check argument slots,
result/operand type, kind, rank/dimensions, literal caches, declarations and cycles;
static, KIND and empty-array paths retain these checks. Evaluated NaN/infinity,
out-of-range REAL4 storage and domain failures are checked errors.

ACOSD/ASIND use the host radian intrinsic and degree conversion at the input kind.
SIND/COSD reduce the absolute represented finite angle modulo 360 before radians
conversion, then use quadrant/complement identities. This avoids overflow for
large finite input and cancellation near quarter turns. Represented quarter
turns and half-valued trigonometric cases are handled exactly. Tiny negative
arguments are not first mapped to 360, preserving their sign and magnitude.
Zero signs follow the documented odd SIND/ASIND and even COSD convention; SIND
at a positive 180-degree turn is negative zero, at 360 is positive zero.
REAL4 evaluation of direct degree functions uses binary64 intermediates and then
rounds to the requested kind. No new resource limit or numerical compiler flag is
introduced. There is no claim of universal correctly rounded transcendental math.

In the isolated degree-intrinsic checkpoint, three whole original programs
passed: demo_acosd and demo_asind with exact output tokens, demo_sind with exact
formatted bytes. Its then-current demo_cosd T20 prerequisite is supported by the
later [positioning extension](POSITION-FORMATS.md). Current complete-program
results are reported separately in the release verification. See [suite and exact counts](../tests/degree_trig/README.md).

GNU 14.2 has an observed REAL4 SIND signed-zero inconsistency: runtime variables
produce +0 for -0, while a folded literal produces -0, at both -O0 and -O2.
The isolated test is GNU compile-only with an independent signed-zero oracle;
ordinary successful cases still require their fixed numerical/output expectations.
The comparator is not relaxed for this observation. See
[recorded evidence](../tests/degree_trig/gnu-signed-zero-observation.json).

Primary references: [ACOSD](https://gcc.gnu.org/onlinedocs/gfortran/ACOSD.html),
[ASIND](https://gcc.gnu.org/onlinedocs/gfortran/ASIND.html),
[SIND](https://gcc.gnu.org/onlinedocs/gfortran/SIND.html) and
[COSD](https://gcc.gnu.org/onlinedocs/gfortran/COSD.html).
