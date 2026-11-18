# PACK

`PACK(ARRAY,MASK[,VECTOR])` is executed directly by the interpreter. GNU Fortran
is used only for independent tests, not as an execution backend.

## Supported arguments

- ARRAY: rank one or two, with INTEGER(4/8), REAL(4/8), default LOGICAL, or
  fixed-length default CHARACTER elements.
- MASK: a scalar default LOGICAL value or a LOGICAL array conforming to ARRAY
  in rank and every dimension extent. Equal total size alone is not sufficient.
  Different lower bounds are allowed.
- VECTOR: optional rank-one array with exactly ARRAY's type, kind, and CHARACTER
  length. Its size must be at least the number of selected ARRAY elements.
- Positional and `ARRAY=`, `MASK=`, `VECTOR=` keyword arguments follow ordinary
  association rules. A user-defined procedure named PACK can shadow the intrinsic.

Complex and derived arrays, higher ranks, nondefault CHARACTER/LOGICAL kinds,
and non-CHARACTER OPTIONAL array dummies remain outside the
existing subset. This does not introduce allocation or general array resizing.

## Result

The rank-one result preserves ARRAY's element type and kind, and its CHARACTER
length when applicable. Selected elements appear in Fortran array element order:
the first subscript varies fastest. Sections preserve their own selected order,
including reversed sections.

Without VECTOR, the result contains exactly the selected elements. A scalar
true MASK selects every ARRAY element; scalar false selects none. With VECTOR,
the result has VECTOR's size. If `k` elements were selected, positions `k+1`
through `size(VECTOR)` come from those same positions in VECTOR, not its prefix.

```fortran
print *, pack([10,20,30,40], [.false.,.true.,.false.,.true.], [5,6,7,8,9])
! 20 40 7 8 9
```

Zero-sized input, an all-false mask, and zero-sized results are supported.
An empty ARRAY with VECTOR returns all of VECTOR. A false scalar MASK can use
VECTOR shorter than ARRAY because no source elements are selected. A zero-length
VECTOR is invalid when at least one source element is selected. Result inquiry
bounds are one through the result size, including upper bound zero when empty.

Results compose with assignment, constructors, SIZE/LBOUND/UBOUND, reductions,
PACK itself, supported array-valued functions, assumed-shape numeric/logical
IN arguments, and parameter initializers. COUNT-dependent automatic result
bounds require the separate COUNT specification-expression support.

## Safety and evaluation

The adapter independently checks argument association, types, ranks, known
shapes, kinds, and cached result metadata. Runtime validation repeats relevant
checks for direct IR callers, including empty results and unevaluated KIND
inquiries.

At execution, all operand descriptors are prepared, then MASK is evaluated and
its selected positions frozen once per statement. The result is materialized
once, in linear work, before assignment. This supports overlapping source or
VECTOR destinations and avoids repeating an impure elemental mask during size
and value evaluation. Scalar MASK is evaluated once even for an empty ARRAY.

Only selected ARRAY values and the used VECTOR tail are read directly; unused
source elements and unused VECTOR prefix elements do not cause uninitialized
reads. Operand expressions may perform work to establish their own shapes or
cached results. An undefined selected element, mask value, or used tail value
is an explicit runtime error. VECTOR underflow and dynamic MASK nonconformance
are checked even when an enclosing result would be empty.

The selection scan and result construction consume the shared execution budget.
Input, result, and aggregate cached temporary sizes respect `max_array_elements`.
Allocation failures for selection indices and result storage are diagnosed.
This is the same bounded interpreter model, not an OS sandbox guarantee.

## Tests and oracle limits

[tests/pack_intrinsic](../tests/pack_intrinsic) contains 49 CLI cases, including
26 successful GNU runtime comparisons, 13 GNU compile rejections, 7 compile-only
checks, and 3 interpreter safety-only cases. Native tests add 225 parser,
adapter, runtime, empty-result, CHARACTER, and unevaluated KIND checks.

Two GNU 14.2 discrepancies are recorded explicitly rather than counted as
runtime matches:

- PACK of zero-length CHARACTER values crashed in libgfortran with SIGFPE; the
  interpreter's zero-length test uses a hand-checked expected result and a
  compile-only GNU check.
- GNU accepted unequal ARRAY/VECTOR CHARACTER lengths without diagnosis; the
  interpreter rejects differing type parameters. That test is compile-only.

The PACK argument/result rules are documented in the
[Intel compiler reference](https://www.intel.com/content/www/us/en/docs/fortran-compiler/developer-guide-reference/2023-2/pack-function.html)
and [GNU compiler reference](https://gcc.gnu.org/onlinedocs/gfortran/PACK.html).
