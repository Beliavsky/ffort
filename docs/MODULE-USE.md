# Same-file module dependencies and chained constants

Modules may use modules defined earlier in the same source file. Plain USE and
USE ONLY use the same supported entities as main-program imports: PARAMETER
constants, procedures, derived types, named generics and defined operators.
Imported names are visible in that module's declarations and contained
procedures. An internal main procedure retains only its main program's imports.
Every import records its owning scope; imports in unrelated modules or the main
program do not leak into other scopes.

PUBLIC/PRIVATE and ONLY are enforced at the defining module. Local module
entities may not collide with imported names. A procedure-local declaration or
dummy may shadow host-associated data. Duplicate USE statements in one
scope remain unsupported. Different modules may each use the same dependency.
The source order must be acyclic and dependencies must come first; the main may
use any earlier module. The existing 16-module limit allows up to 136 scoped
USE associations across the file.

A dependency chain works when each module declares the constants or procedures
that it exports. Re-export of a name merely imported from another module remains
outside this increment, including an accessibility statement naming such an
import. nonintrinsic module USE renaming, nonintrinsic USE inside procedure bodies, separately
compiled module files remain unsupported. Mutable module state is documented
in [MUTABLE-MODULES.md](MUTABLE-MODULES.md).

## Original utility declaration forms

The strict producer now retains every initialized entity in a module declaration,
including dependent PARAMETER declarations such as:

```fortran
integer, parameter :: i32=selected_int_kind(9), long_int=selected_int_kind(15), &
                      i64=long_int, bad_int=-999
```

Earlier entities are usable in later initializers. The recognizer still rejects
self/forward references, nonconstant initializers and unsupported kinds. This
also covers mixed scalar/array constants and fixed-length CHARACTER constants.
Inferred-length CHARACTER PARAMETER declarations and CHAR/ACHAR initializers
are covered separately by [CHARACTER-PARAMETERS.md](CHARACTER-PARAMETERS.md).

`tests/module_use/kind_chain.f90` retains the complete original `kind_mod`
specification with only newline normalization. `utility_constants.f90` retains
that module, the original utility USE ONLY, and the original chained REAL64 and
INTEGER constant declarations. `source_map.json` records exact source ranges and
normalized SHA-256 hashes. The original qp inquiry is retained but not used as a
storage kind: the interpreter's wider-kind limitation is unchanged.

## Checks

- `fpm test --profile debug` includes a direct producer declaration-count check,
  a source/adapter baseline and nine independent IR mutation rejections.
- `python3 tests/module_use/run_tests.py --candidate PATH_TO_INTERPRETER` runs 26
  source cases against GNU Fortran, including 13 successful comparisons and 13
  rejected/unsupported cases. Every GNU compile uses a fresh directory so stale
  `.mod` files cannot mask missing or forward imports.
- The tests cover the original kind/constants forms, three-module dependencies,
  plain/ONLY/empty-ONLY imports, exact INTEGER(8), arrays, generics, types,
  operators, scope isolation, shadowing, PRIVATE, ambiguity, collisions,
  self/forward references, and the remaining re-export boundary.

Explicit intrinsic ISO_FORTRAN_ENV ONLY aliases are documented separately in
[ISO-FORTRAN-ENV-ALIASES.md](ISO-FORTRAN-ENV-ALIASES.md); ordinary module renaming remains unsupported.
