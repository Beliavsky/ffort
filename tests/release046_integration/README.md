# Independent 0.46 composition

These 31 small sources are synthetic cross-feature checks, not edited originals
or claims that a complete utility library is supported. They target constructor
implied-DO ownership, vector LBOUND/UBOUND with KIND4/8, default-CHARACTER MIN/MAX
and scalar NORM2 inside surrounding array expressions.

```sh
python3 tests/release046_integration/test_runner.py
python3 tests/release046_integration/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
```

Twenty-four cases have strict GNU14.2 executions: 22 compare every output byte,
including CHARACTER padding and record endings; two opt in to exact Decimal
numeric tokens with signed-zero and exact large-integer preservation. There are
no floating tolerances or general text/whitespace/case normalization. Three
controlled runtime failures and three deliberate subset boundaries are GNU compile-only, never executed by the reference. Candidate errors
require named, source-located diagnostics and exact prior committed output.

One further successful-candidate case has an independent CHARACTER expectation
but is **not** a GNU execution agreement. GNU14.2 rejects
`min(['Z','A'],['YY','B '])` in strict mode with a same-length diagnostic. The
expected result `[YY][A ]` follows elementwise blank comparison and the longest
operand length. The runner requires the separately identified compiler rejection
and does not retry in permissive modes, normalize away padding, run a stale
binary, or turn a compiler ICE into an accepted rejection. An unexpected ICE or
new compiler failure remains a failed test. Deferred-array MIN patterns known
to crash GNU are not silently substituted or presented as executed references.

The suite covers nested controls dependent on outer indices, sibling index reuse,
module-host/OPTIONAL/active-DO shadowing, exact INTEGER8 runtime controls, callee scope,
zero-trip undefined operands, metadata-only inquiries, per-axis empty bounds,
whole-object versus expression/parenthesized bounds, transpose/reallocation,
CHARACTER keyword ordering, unequal-length scalar expansion, and retained
nonadvancing output on failure. No resource cap or supported-rank restriction is
weakened. Typed nonempty numeric constructors and explicit index type syntax are
not added by these tests.

All source bytes are pinned in the manifest and independent SOURCE-IDENTITY.json.
The generator reproduces the exact sources and manifest. GNU compilation uses
strict Fortran2018, runtime checks and floating exception traps in fresh temporary
directories; stdin is closed. No user files or external input bindings are used.
The candidate executable hash is checked before and after the suite. Twenty-nine
adversarial harness tests cover records, Decimal precision/subnormals/signed zero,
INTEGER8 values beyond binary64 precision, diagnostics/status/atomicity, strict
silence, crash detection, compile-only and known-compiler-rejection distinctions,
and generator identity. Full clean release certification is separate.

## Preserved first-preview boundaries

The first immutable-preview run found three GNU-valid cases outside the existing
subset: untyped constructors with deferred-length CHARACTER items, a contained
function reading a mutable main-program local, and rank-three RESHAPE. The feature
owners confirmed those boundaries. Their source bytes remain exactly as first
prepared; only their declared stage/diagnostic expectations were corrected to
GNU compile-only/candidate source rejection. The rank-two constructor-leaf source
was already an explicit subset boundary. No core feature or cap was broadened.

Three new, separately named sources test the supported alternatives: an explicit
CHARACTER(4) constructor snapshots the deferred-length scalar MIN result; a module
function observes the real module variable rather than the constructor index;
and rank-one slices initialize a declared rank-three array before scalar NORM2
broadcast and vector bounds. These all execute with byte-exact GNU outputs.
The original 28 source hashes are preserved in the preparation receipt outside
this suite; SOURCE-IDENTITY.json pins all 31 final sources.

## 0.48 descriptor-length constructor promotion

The unchanged `allocated_character_result_length` now passes strict check and
execution with byte-exact GNU output `4[a   ][a   ]` plus one newline. Its whole
allocated CHARACTER variable supplies the descriptor length to the untyped
constructor. The historical first-preview rejection above remains evidence of
0.46 behavior, not the current expected result. The manifest and generator now
classify this source as success/GNU execution; all 31 Fortran sources remain
byte-identical. The other three subset boundaries are unchanged.
