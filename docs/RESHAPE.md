# Bounded RESHAPE

`RESHAPE(SOURCE, SHAPE [, PAD, ORDER])` accepts rank-one or rank-two intrinsic
arrays and produces a rank-one or rank-two result. INTEGER/REAL kinds 4 and 8,
LOGICAL, and fixed-length default-kind CHARACTER are supported. PAD, when
present, must match SOURCE's type, kind, and CHARACTER length, but need not have
the same rank or extents.

SHAPE is an INTEGER vector whose **length is statically known to be 1 or 2**.
Its values can be runtime expressions, including `[size(matrix)]`. Both bracket
and slash constructors work. The default result traversal is Fortran array
element order (first dimension fastest). ORDER must be an INTEGER permutation
of `[1]` or `[1,2]`; `[2,1]` makes the second result dimension vary fastest.
The result's lower bounds are one. SOURCE and PAD are read in array element
order, including sections with nonunit/reversed strides. Surplus SOURCE values
are ignored; after SOURCE is exhausted, PAD is cycled repeatedly.

Positional arguments, mixed positional/keyword arguments, arbitrary keyword
ordering, and `order=` without PAD are supported. Duplicate or unknown keywords,
missing required arguments, positional arguments after keywords, incompatible
types/kinds, and unsupported ranks fail at compilation.

## Limits and validation

- Each SHAPE extent is between zero and `max_array_elements` inclusive. The
  product must not exceed that same shared cap (default 1,000,000). Even an empty
  result rejects an individually over-cap extent. Division guards run before
  multiplication or default-INTEGER conversion, including with INTEGER(8) SHAPE.
- Runtime SHAPE and ORDER values are evaluated and frozen once per expression
  preparation. Shape, permutation and PAD-sufficiency checks also run for empty
  results. Negative extents, invalid permutations, too-short SOURCE without
  nonempty PAD, and dynamically wrong ORDER length fail before PRINT or target
  assignment emits/commits values.
- Empty results do not read SOURCE/PAD elements. Unused PAD values are not read.
  KIND remains an unevaluated inquiry, while validating IR metadata.
- No full RESHAPE temporary is allocated. Elements are mapped lazily to SOURCE
  or PAD. Existing function-result caches, assignment staging, expression/call
  element caps, CHARACTER length cap, PRINT cap and step budget still apply.
  These per-region caps do not constitute a global process-byte memory limit.
- The independent syntax recognizer, FortFront adapter, and runtime separately
  check the RESHAPE argument/result contract. The runtime guards malformed IR
  references, cycles, counts, slots, types, kinds, rank, extent and shape caches.

## Explicit boundaries

Unknown-length SHAPE expressions (for example a runtime array section or
assumed-shape dummy used directly as SHAPE), result ranks above two, derived
and COMPLEX types, deferred/assumed-length CHARACTER SOURCE, and direct
OPTIONAL PAD/ORDER dummies are not supported. Present optional dummies can be
copied into ordinary local arrays first. An absent optional dummy is not an
empty PAD.

Constant rank-one and rank-two declaration/PARAMETER initializers are supported.
When per-dimension extents are not statically cached, the bounded constant shape
evaluator prepares and validates the actual dimensions before comparing each
axis with the declared array. This includes empty arrays, for which equal total
size alone is not conformance. The independent adapter repeats that shape check.
RESHAPE metadata remains conservative; no runtime safety checks are bypassed or
replaced by a trusted shape cache. Constant outer expressions may wrap RESHAPE.
Mutable initialized procedure locals remain unsupported because of implicit SAVE.
This does not claim general Fortran RESHAPE support or full xutilities module support.

## Verification

Run `fpm test --target test_reshape` and
`fpm test --target test_reshape_initializers`, then:

```
python tests/reshape/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The native test mutates parser IR and checks independent adapter and runtime
rejection. The source suite covers types/kinds, both orders, padding and repeated
padding, empty arrays, negative and oversized extents, zero/huge combinations,
INTEGER(8) overflow inputs, malformed argument association, undefined values,
and exact cap boundaries. Valid programs are compared with GNU Fortran using
`-std=f2018 -pedantic-errors -fcheck=all`; invalid/safety inputs are never run by
the GNU oracle. Independent literal expectations supplement the oracle.

`tests/reshape/original_vector.f90` embeds the original `vector` procedure from
`tests/utilities_slices/source_parts/routines/093_vector.f90` without textual
changes other than normalizing line endings, wrapped in a small module with
`dp` and a standalone driver. It covers ordinary/reversed matrices and an empty
matrix. It is a focused replay, not a claim that the complete source compiles.
