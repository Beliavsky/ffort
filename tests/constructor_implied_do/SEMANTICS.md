# Standards scope and independently observed GNU behavior

## Primary references

The [Fortran 2018 interpretation draft, J3/18-007r1](https://j3-fortran.org/doc/year/18/18-007r1.pdf),
§7.8 (printed pp. 88–90), §11.1.7.4 and §19.4 (p. 500), establishes:

- An array constructor produces a rank-one sequence. Array leaves contribute
  their elements in array-element order; no produced values means zero size.
- An untyped constructor requires matching leaf type, kind and length.
- The index is a statement-local scalar integer. Without an explicit index type
  specification, it inherits type/kind from its enclosing declaration, but no
  other attributes. Scalar-variable names may be shadowed; array, PARAMETER and
  procedure names may not. The outer variable's state is separate.
- Nested implied-DOs cannot reuse the same index name. Siblings may reuse it.
- Loop initialization/execution follows ordinary DO semantics: controls are
  established per loop invocation, a nonzero step determines direction, and a
  zero-trip loop contributes no elements. The index itself has no surviving
  outer-variable final value.
- Zero-trip CHARACTER length cannot depend on the index or a nonconstant
  expression. Explicit F2018 index type specification is standard syntax.

[J3 interpretation 000083, 00-124r1](https://j3-fortran.org/doc/year/00/00-124r1.txt)
clarifies that the index's scope includes all of its own control expressions.
Thus `(i,i=1,i)` cannot obtain its final bound from an outer `i` and is invalid.
This restriction concerns value reads. Under §16.1 paragraph 2, inquiry operands
may have undefined values: KIND(i), DIGITS(i), HUGE(i), including metadata-only
expression operands such as KIND(i+1), are valid controls. A separate strict GNU
followup confirms nine such cases; KIND(i)+i still rejects.

## Local GNU 14.2 observations

Compiler: GNU Fortran (Debian 14.2.0-19) 14.2.0. All probes used strict F2018,
pedantic errors, runtime checks and O0. `probes/gnu-probes.json` and
`probes/gnu-probes-extra.json` preserve complete output and diagnostic text.

GNU confirms outer scalar preservation for forward, negative-step and zero-trip
constructors; an uninitialized outer scalar is not read by a valid constructor;
active outer DO variables and allocated/pointer-associated scalar names are
preserved. It rejects array/PARAMETER names, nested repeated names, noninteger
controls, constant zero strides and own-index value reads under these strict flags.

Two GNU limitations are separated from the semantic oracle:

1. With `integer(8)::i,a(3)`, constant bounds
   `9007199254740993_8,9007199254740997_8,2_8` unexpectedly produced `1,3,5`.
   The retained `kind_inherited.f90` probe and output demonstrate this exact
   behavior. `kind8_runtime.f90`, using INTEGER(8) runtime bound variables with
   the same values, produced `9007199254740993,9007199254740995,9007199254740997`.
   `kind8_leaf_precision.f90` also preserved neighboring large INTEGER(8)
   values. The ordinary suite uses the working runtime controls and precise
   large leaf values. It never blesses truncation or relaxes integer comparison.
2. GNU rejects `(i,integer::i=1,3)` although explicit index typing belongs to
   F2018. `explicit_index_type` is tagged as a GNU/subset limitation, not
   standard-invalid evidence.

One preliminary GNU run also rejected an unparenthesized second body comparison
`[(i>1,i==2,i=1,3)]` as iterator syntax. The final valid fixture parenthesizes
`(i==2)`, preserving its intended values rather than requiring that parser edge.

The committed oracle outputs come from the final generated fixtures, not from
these exploratory anomaly probes. Compile-only negatives are never run.
