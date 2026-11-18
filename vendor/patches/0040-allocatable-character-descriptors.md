# 0040: Deferred CHARACTER dummy lengths

Local compatibility patch against bundled FortFront. Upstream notices and license
remain unchanged; upstream authorship or endorsement is not implied.

The strict dummy-type builder recognizes `:` as a dynamic CHARACTER length,
alongside `*`, on declaration and parameter-declaration nodes. This prevents
provisional length inference from rejecting a legal deferred allocatable call.
Type, CHARACTER kind and rank matching remain active. The independent interpreter
adapter and runtime separately require matching deferred/nondeferred attributes,
whole allocatable actuals, matching fixed lengths, and valid live descriptors.

Apply from `vendor/fortfront` with
`patch -p1 < ../patches/0040-allocatable-character-descriptors.patch`.

See `tests/allocatable_character` and `test/test_allocatable_character.f90` for
positive association checks, invalid fixed/deferred combinations and mutations.
