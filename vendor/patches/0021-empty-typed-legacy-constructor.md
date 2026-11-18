# Empty typed legacy constructors

Preserves a type-spec and zero-element array literal for `(/ character(2) :: /)`.
The previous legacy parser handled an untyped empty constructor before reading
a type-spec, but attempted to parse an element after a typed constructor's `::`.
The modern bracket spelling already worked.

Applied after patches 0001 through 0020. Affected producer file:
`src/parser/expressions/parser_expression_arrays.f90`.
Verified by `tests/character_arrays/cases/typed_empty_slash.f90` against GNU Fortran
and by the native producer test.
