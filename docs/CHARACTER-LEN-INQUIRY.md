# CHARACTER %LEN inquiry

A whole named default-CHARACTER scalar or rank-one through rank-three array may
use `name%len` as an expression. The result is a default INTEGER scalar (kind 4),
including for an empty array. It reports the element length, not array size. This
is a type-parameter inquiry, not a component variable: it takes no argument list
and cannot be assigned to. Case-insensitive spelling is supported.

The bounded parser lowers the inquiry to the existing LEN expression. The
independent FortFront adapter checks the original component-access spelling and
base binding. Producer patch 0084 independently reports INTEGER scalar metadata
and prevents a CHARACTER array base from supplying the result rank. Ordinary
derived-type component resolution remains separate. No intrinsic registry entry
is added.

## Length and evaluation rules

- Fixed declared lengths can be inquired about without reading undefined data,
  including zero length, empty arrays and unallocated fixed-length allocatables.
- Deferred lengths require an allocated object when the inquiry is evaluated.
  Reallocation and deallocation retain the existing scalar/array lifetime rules.
- Assumed-length dummies use the associated length. An absent OPTIONAL operand
  cannot supply a length value.
- KIND(name%len) is a metadata-only inquiry; it does not evaluate the inner length
  or read absent/unallocated data. It still validates the entire operand tree.
- Fixed-length inquiries may initialize INTEGER parameters and supported
  declaration lengths/extents. Runtime specification lengths use the existing
  bounded specification-expression rules. Fixed whole-variable LEN(name)
  parameter initializers receive the matching adapter correction.

The source adapter and runtime check result kind/rank, argument count and indexes,
unused metadata, whole-variable binding, cached length and static/dynamic shape.
The shared whole-variable validator does bounded arithmetic on declaration caches,
without evaluating bounds or allocation data. KIND and empty enclosing expressions
retain these validation checks without evaluating the inquiry value.

This extension does not admit `%kind`, CHARACTER kinds other than the existing
default, `%len(...)`, inquiry assignment, or inquiry suffixes on array elements,
sections, substrings, literals, parenthesized expressions or function results.
Some excluded forms are valid Fortran; the manifest separates supported GNU
programs at the boundary from invalid syntax. Existing reserved-name restrictions
on a user function or derived component named `len` remain unchanged. The existing
LEN intrinsic's optional KIND argument is not added by this syntax extension.

## Verification

The 57 focused cases comprise 40 GNU execution agreements, nine GNU compile-only
checks, seven GNU compile rejections and one explicit oracle skip. The untouched
M_intrinsics `example/demo_len.f90` is copied byte-for-byte from commit
`fc14233036d910e3678d350efc24609e11475067`; source and license hashes are recorded
in `tests/character_len_inquiry/upstream.json`. Its complete output is compared
by tokens because list-directed whitespace is processor-dependent. Other success
probes assert their values internally and require truly empty stdout/stderr.

GNU Fortran 14.2 ICEs while compiling the valid metadata-only parameter form
`integer,parameter::k=kind(s%len)` for deferred allocatable CHARACTER s. That
compile failure is retained separately, never counted as a GNU rejection or an
execution agreement. The candidate expectation follows the existing metadata-only
KIND policy. Adjacent runtime KIND(s%len) and parameter KIND(LEN(s)) probes do
execute successfully with GNU. The primary reference is
[J3/18-007r1](https://j3-fortran.org/doc/year/18/18-007r1.pdf), sections 9.4.5,
16.1 paragraph 2 and 16.9.108: inquiry results depend on properties rather than
argument values, and KIND returns a default INTEGER scalar.

The native suite checks 640 adapter/runtime outcomes: five valid contexts and
63 malformed-IR variants per context, covering ordinary, KIND and empty evaluation.
Ten independent producer checks distinguish scalar/array CHARACTER inquiries from
ordinary derived components. Twenty-seven adversarial runner/provenance tests enforce exit,
diagnostic and output rules. These focused results are separate from the
integrator's complete clean release validation. No existing Fortran fixture is
modified.
