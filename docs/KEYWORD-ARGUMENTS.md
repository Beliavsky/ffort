# Keyword actual arguments (0.12.0)

Supported user functions and subroutines now accept actual arguments by the
names of their dummy arguments, including module, imported and internal
procedures. The supported array intrinsics accept their standard argument
names:

| Intrinsic | Required arguments | Optional arguments |
| --- | --- | --- |
| SUM, PRODUCT, MINVAL, MAXVAL | ARRAY | DIM, MASK |
| DOT_PRODUCT | VECTOR_A, VECTOR_B | none |
| MATMUL | MATRIX_A, MATRIX_B | none |
| SIZE | ARRAY | DIM |
| LBOUND, UBOUND | ARRAY, DIM | none in this subset |

Names are case-insensitive. Positional arguments must precede all keywords;
keywords can then appear in any order. Every required argument must occur
exactly once. Unknown names, repeated keywords, positional/keyword collisions,
missing arguments and positional arguments after keywords fail before output.

```fortran
print *, sum(mask=selected, array=matrix, dim=1)
print *, sum(matrix, mask=selected)
print *, matmul(matrix_b=right, matrix_a=left)
print *, size(dim=2, array=matrix)
print *, difference(right=3, left=10)
call scale(value, output=answer, factor=3)
```

The existing two-positional-argument reduction overload `(ARRAY, MASK)` remains
supported. When later keywords are present, a second positional argument
occupies DIM: `sum(a,mask,dim=1)` is invalid, as in GNU Fortran. Use
`sum(a,mask=mask,dim=1)` instead. Named DIM always requires scalar INTEGER;
named MASK always requires LOGICAL. A wrong type cannot silently select a
different overload.

## Association and execution

The recognizer first parses every actual expression and associates each one
with the intrinsic or procedure signature. It then stores the existing compact
positional representation. The FortFront adapter independently reconstructs
association from the source AST, checks the keyword wrapper and name, and
matches the value expression to the corresponding IR slot. An unmatched
keyword wrapper is rejected rather than mistaken for an executable assignment
or ignored. A small producer-side patch marks expression-call keyword wrappers
consistently with existing CALL wrappers; see vendor patch 0008. Patch 0009
corrects conversion-intrinsic result type/rank inference for nested actuals.

Runtime code is unchanged. Existing checks apply after association: exact
procedure type, REAL kind and rank; definability of OUT/INOUT actuals; active
DO variables; overlapping writable actuals; sections and copy-back;
initialization flags; conformance; work and allocation limits; and atomic
statement evaluation. Argument evaluation uses canonical dummy/intrinsic
order, which is deterministic here but is not a Fortran source-order guarantee.

Array inquiries still inspect shape without reading array elements. Reduction
MASK and empty-result policies, numeric kinds and overflow checks, expression
lower bounds and section semantics are unchanged. Optional non-CHARACTER-array/derived-type dummies,
absent arguments, KIND arguments, scalar elemental intrinsic keywords,
LBOUND/UBOUND without DIM and unsupported syntax remain outside the subset.

See `examples/keyword_arguments.f90`, the independent GNU-oracle corpus in
`tests/keyword_arguments_independent`, and the native adapter and producer
regressions in `test/test_keyword_*.f90`.

Scalar INTEGER/REAL/LOGICAL OPTIONAL user dummies and PRESENT are supported;
see [OPTIONAL-ARGUMENTS.md](OPTIONAL-ARGUMENTS.md) for omitted-slot association.
