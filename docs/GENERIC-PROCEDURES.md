# Named generic module procedures

A named module interface groups specific module functions or subroutines:

```fortran
module operations
  implicit none
  interface twice
    module procedure twice_int, twice_real
  end interface twice
contains
  integer function twice_int(x) result(y)
    integer, intent(in) :: x
    y = 2*x
  end function
  real function twice_real(x) result(y)
    real, intent(in) :: x
    y = 2*x
  end function
end module

program main
  use operations, only: twice
  implicit none
  print *, twice(2.3), twice(4)
end program
```

The example prints values approximately `4.6 8`. GNU and interpreter default
REAL formatting differ; the interpreter prints `4.59999990 8`.

## Supported contract

- Named interfaces in same-file module specification parts, with one or more
  `module procedure` statements. A statement may list several specifics and
  may include `::`. An optional matching name may follow `end interface`.
- Functions or subroutines, but not a mixture within one generic interface.
  The underlying procedure restrictions are unchanged. Supported intrinsic scalar and rank-one/rank-two dummies may be OPTIONAL.
- Exact actual-to-dummy type, INTEGER/REAL kind, and rank matching. No implicit
  conversion is performed. The result's type is not used to select a specific.
- Positional and keyword arguments, including keyword reordering and a
  positional prefix followed by keywords. Each candidate uses its own dummy
  names. Wrong keywords, duplicates, arity mismatches and missing specifics
  produce compilation errors before any output.
- Supported scalar and rank-one/rank-two arguments and ELEMENTAL lifting.
  An exact-rank match takes precedence over a scalar ELEMENTAL candidate that
  would require array lifting. Shape and writable-actual checks still apply
  after the unique specific has been selected.
- Module PUBLIC/PRIVATE and plain USE or USE ONLY. A public generic may expose
  private specifics through that generic, without making their specific names
  callable. Calls inside its own module can use a private generic. Main-program
  internal procedures inherit their host's USE association.
- At most 256 named generic interfaces, with 16 specifics per interface, within
  the existing module/procedure/argument limits. Duplicate specifics and
  ambiguous signatures are rejected, even if the generic is never called.

## Explicit boundaries

This does not add interfaces outside modules, interface-body/external
procedures, OPTIONAL derived-type arguments, procedure dummy arguments, nonintrinsic module USE renaming,
constructor overrides or defined assignment. Defined unary/binary operator
interfaces are described separately in [DEFINED-OPERATORS.md](DEFINED-OPERATORS.md). Repeated same-name interface blocks, a generic
sharing a name with one of its specifics, and combining same-name generics from
multiple imported modules are also outside this bounded implementation.
Existing recursion, purity, INTENT, supported types and array-result restrictions
continue to apply to the selected specific.

## Independent checking

The recognizer records interface identity and the selected specific in the
private IR; execution uses the existing function/subroutine evaluator. The
FortFront adapter separately checks interface AST names, module ownership,
visibility, specific lists and bindings. It resolves the source call to the
visible generic declaration, repeats selection using the AST keyword order,
and independently checks every actual expression and the selected declaration.
It does not execute source by compiling it with GNU Fortran.

FortFront's strict explicit-interface checker originally recognized specific
names but omitted named generic interfaces. Retained patch 0022 recognizes an
actual scoped generic binding for function and subroutine references. It does
not add names to the process-global cache and does not expose private or
USE-excluded interfaces. Full overload association remains independently
checked by the interpreter recognizer and adapter.

`test/test_generic_frontend.f90` covers one valid fixture plus 19 metadata
mutations. `test/test_generic_producers.f90` directly checks seven producer
visibility/explicit-interface cases. The GNU differential corpus and precise
expectations are in `tests/generic_interfaces`.

Retained patch 0024 also fixes per-occurrence result metadata. Named generic
calls select the declared specific before copying its result type/kind and
ELEMENTAL rank; an interface itself has no unique result type. This preserves
REAL64 array-expression actuals such as `twice(x**2)` and specifics whose result
type differs from their dummy type. `test_generic_result_producer.f90` directly
checks the producer's call metadata before checking the same source through
the adapter. The existing adapter occurrence type/kind/rank check is retained.

Explicit intrinsic ISO_FORTRAN_ENV ONLY aliases are documented separately in
[ISO-FORTRAN-ENV-ALIASES.md](ISO-FORTRAN-ENV-ALIASES.md); ordinary module renaming remains unsupported.
