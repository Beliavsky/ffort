# Named scalar CHARACTER parameter formats

PRINT and the already-supported positional WRITE forms accept the name of a
visible, initialized scalar CHARACTER PARAMETER as their format. This applies to
standard-output WRITE, scalar/array-element internal WRITE and the existing defined-output
child WRITE callback. Literal formats and list-directed `*` retain their prior
behavior. A named parameter whose value is `*` is not list-directed output; its
value must be a valid parenthesized format in the supported format subset.

The parameter's declaration may use a supported constant expression, including
concatenation, another parameter or REPEAT. Normal CHARACTER initialization
padding/truncation is applied before the format is validated. Name lookup is
case-insensitive and respects local shadowing, host association, module imports,
visibility and ambiguity. A mutable local variable shadows a same-named host
parameter and is rejected rather than silently falling back to the host value.

This is deliberately narrower than general Fortran CHARACTER format expressions.
Mutable variables, dummy arguments, arrays, array elements, substrings,
parenthesized or concatenated expressions at the I/O statement, labels and new
keyworded I/O-control forms are not added. The initializer may concatenate, but
the I/O statement must name the scalar parameter directly. The broader standard
language forms are described by Intel's [FMT specification](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2026-0/format-specifier-fmt.html).

## Independent validation and execution

The subset parser resolves a ready scalar CHARACTER PARAMETER and freezes its
initialized value into the same format field used for literal output. The
canonical producer retains the original format name. The adapter independently
resolves that name in the matched source scope, verifies exact declaration
identity, type/rank, PARAMETER state, initializer/cache agreement and CHARACTER
length, then compares the frozen format bytes and length. Literal format
comparison also checks length, preventing blank-padding equality from disguising
an altered trailing byte. No new vendor metadata or executable format expression
is introduced. The runtime consumes this frozen value, not mutable format state,
and independently revalidates its grammar, descriptor/item association and caps.
The adapter is the source-binding check; direct runtime IR has no source text and
is not claimed to re-resolve a PARAMETER name.

Ordinary record reversion, same-record unlimited groups, reached literal edits,
DT callbacks, significant CHARACTER spaces and statement output staging are
unchanged. No runtime formatter code changes. The existing limits remain 64
format nodes, 31 nested groups, 65536 expanded values, 65536 staged formatted
bytes and 262144 traversal/data operations. Internal assignment and external
output happen only after the existing whole-statement validation/rendering path.
No arithmetic or array limit is raised.

## Tests and unchanged originals

- 50 focused cases: 24 executions, 23 source rejections and 3 runtime boundaries.
  All successful checks must be silent. Every formatted output is byte-exact
  against strict GNU Fortran, with independent structural expected records.
- Four runner self-tests cover spacing, line boundaries, integer/exponent spelling,
  signed zero, tiny nonzero values, expected records and silent check mode.
- 33 native assertions independently inspect producer names and reject adapter
  mutations to source identity, type/rank, PARAMETER state, initialized values,
  caches and exact format length, including coordinated cache/IR changes. Direct
  runtime mutations prove malformed frozen formats still fail without execution.
- Five complete original M_intrinsics files are retained byte-for-byte with MIT
  license/provenance. In a combined build with ASIN/ATAN/ATAN2, unchanged
  `demo_asin` executes with byte-for-byte GNU agreement. The format-only patch
  does not claim to provide ASIN by itself.

The other original files document later gates, not complete execution passes:
`demo_shape` reaches unsupported DIM-omitted LBOUND/UBOUND; `demo_maxexponent`
reaches unsupported REAL128 literals; after NEW_LINE support, `demo_acos`
reaches its first complex literal at line 20, column 40 (`Expected ), found ,`); `demo_nearest` passes checking and reaches the existing
finite-range rejection at NEAREST(HUGE,+1). Its prior successful records are
byte-exact with GNU and its failing record emits no partial output. For this
original only, the GNU reference uses `-fno-range-check` and omits floating-point
traps because the unchanged program deliberately produces infinity. This is
recorded as a controlled boundary, not a finite successful original run.

GNU execution cases use `-std=f2018 -pedantic-errors -fcheck=all` and
`-ffpe-trap=invalid,zero,overflow`. The interpreter's official debug profile is
separately identified, not described as interpreter-wide `-fcheck=all`.
Existing quoted-single-punctuation parsing limitations are not broadened here.
The entire original utility file retains its intentional 131072-element cap.

## Element-file applicability (0.50)

The same bounded formatter applies to one whole CHARACTER array element as an
internal file. It is still a single record: reached slash advancement/reversion
is rejected rather than spilling into a neighboring element. See
[INTERNAL_WRITE_ELEMENT.md](INTERNAL_WRITE_ELEMENT.md) for evaluate-once indices,
staged commit and the retained PURE, derived-output, section and substring limits.
