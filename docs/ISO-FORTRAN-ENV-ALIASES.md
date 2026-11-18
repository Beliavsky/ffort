# Bounded ISO_FORTRAN_ENV aliases

`use iso_fortran_env, only: ...` and explicit `use, intrinsic :: ...` support local aliases
such as `dp => real64`, mixed with unrenamed imports. REAL32 and INT32 are
INTEGER(4) constants with value 4; REAL64 and INT64 have value 8. Renaming changes
only the local name, not the constant's type or value. Supported named kinds work
in declarations, literal suffixes, parameter expressions and existing host/module
association. Intrinsic ONLY imports may also begin a procedure specification.

REAL128 is an INTEGER(4) constant with value **-1**, indicating that this
interpreter does not implement that REAL kind. This is an availability sentinel,
not a REAL(16) implementation or an alias for REAL(8). Importing, renaming and
using the negative constant in ordinary integer expressions is supported.
Declarations, literals, constructors and conversions requiring the unsupported
REAL kind continue to be rejected, even if their values would be unused.

The [GNU description of ISO_FORTRAN_ENV](https://gcc.gnu.org/onlinedocs/gcc-15.1.0/gfortran/ISO_005fFORTRAN_005fENV.html)
explains that unavailable kinds have negative values. The GNU 14.2 oracle on the
recorded host supports REAL128 with value 16. The two processors intentionally
have different availability constants. Sentinel fixtures therefore have a
separate independent interpreter expectation and are GNU compile-only in the
ordinary differential suite. This is a supported-kind difference, not a GNU bug.
`tests/iso_env_aliases/processor-model.json` records a separate capability probe.

The listed imports plus OUTPUT_UNIT support intrinsic ONLY form with explicit or
omitted nature. An earlier same-named source module wins for omitted nature;
explicit INTRINSIC overrides it, while NON_INTRINSIC never falls back. See
[OUTPUT-UNIT.md](OUTPUT-UNIT.md) for stdout constants and WRITE routing. Empty
ONLY lists, repeated local names, nonintrinsic renaming, other ISO entities and
reserved local names remain outside this bounded slice. No general module
re-export or new kind support is added. Existing scope and name-collision
restrictions remain in force.

## Independent validation

The execution IR retains the remote import name separately from its local alias.
The source adapter validates the exact pair against FortFront's ONLY/rename AST,
including same-valued but distinct REAL/INTEGER entities. Immutable scalar
INTEGER(4) import descriptors, values, flags and shape are checked independently
at runtime, including unused imports and constant/KIND evaluation. An alias cannot
become mutable or advertise another kind by corrupting public IR metadata.

Vendor patch 0063 fixes retained comment trivia in continued USE lists. Its token
helper skips comments and whitespace, never a logical newline. Independent
producer tests cover comments around names/arrows/nature/ONLY, trailing comments,
and rejection of a missing continuation marker. Ordinary source errors are not
accepted by weakening the adapter.

Four complete unchanged M_intrinsics examples pass source checking, execution
and GNU output comparison: `demo_cosh`, `demo_tan`, `demo_tanh` and `demo_epsilon`.
The EPSILON example includes its original contained function and named bare loop.
The original bodies, declarations, literals and output statements are untouched.
Their source hashes, upstream commit and MIT license are recorded with the tests.

The focused suite contains 33 fixtures: 16 ordinary GNU executions, 12 compile-only
boundaries/model differences and five GNU source rejections. Native checks cover
1152 adapter/runtime assertions and 54 independent producer assertions over six
inputs. Seven harness self-tests check that invalid exits, diagnostics, output
leaks, nonfinite numbers and numeric mismatches cannot be accepted.

## 0.53 INTEGER availability additions

The separate [TRAILZ/ISO contract](TRAILZ-ISO-INTEGER-AVAILABILITY.md) adds default-INTEGER availability values INT8=-1 and INT16=-1 and the immutable rank-one INTEGER_KINDS=[4,8]. These describe the interpreter processor, not the GNU host. They are not aliases to kind4 and do not implement INTEGER(1)/(2), small-kind literals, constructors or conversions. INT32/INT64 retain their existing values and alias/source-shadow rules.

INTEGER_KINDS elements and sections retain their imported-array binding across supported aliases and host association. The source adapter preserves the exact owning USE, local/remote identity and written index trees. The scalar-import measurements above are historical evidence, not new aggregate or survey counts. No general re-export or extra integer representation is claimed.
