# Bare values and scalar PARAMETER constants

Starting the executable without a source file in an interactive terminal starts
the existing REPL; piped input without a filename remains batch input. A bare
scalar variable or array element is an expression query and prints its value:

```fortran
integer, parameter :: n = 5
integer :: a(n)
a = 7
n
a(n)
```

The two queries print 5 and 7. Repeated queries do not replay prior statements or
advance random state. Undefined variables/elements still diagnose an error; this
change does not suppress definedness checks. `.vars` and `.info` display scalar
PARAMETER values from their immutable constant cache rather than mutable storage.

This correction admits scalar INTEGER/REAL kind 4 or 8, default LOGICAL, and
fixed-length default CHARACTER PARAMETER declarations before execution. Their
initializers are bounded literal/arithmetic trees or references to earlier scalar
parameters. CHARACTER literals and earlier parameter references are supported;
concatenation, function calls and array PARAMETER constants remain outside this
bounded persistent subset. Initializer type/kind conversion and CHARACTER padding
are checked against the stored constant value before any pending effects.
Parameter constants may provide fixed rank-one array bounds and element indices.

PARAMETERs cannot be assignment, random-output or DO-index targets. Exact
snapshot identities and source-edit gates remain unchanged. A fresh plain scalar
declaration can still use existing no-replay growth after a query; new PARAMETER,
explicitly kinded or array declarations after execution retain the existing
unsupported-growth diagnostic. Declare these before the first query, or use the
explicit rebuild/reset workflow. This does not implement the postponed typed
live-declaration growth feature.

Focused coverage includes the exact `integer, parameter :: n = 5` / `n`
regression, mutable scalar and element values, parameter dimensions, inspection,
immutable-write rejection, healthy suffix continuation and malformed public-IR
constant caches. Full maintained release/Windows certification is not inferred
from these focused results.
