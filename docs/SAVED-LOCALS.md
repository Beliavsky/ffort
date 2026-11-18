# Initialized local SAVE state

Procedure-local intrinsic scalars with constant declaration initializers have
SAVE lifetime. The explicit SAVE declaration attribute is also accepted when
the same declaration supplies the initializer. INTEGER and REAL kinds 4/8,
default LOGICAL, and fixed-length default CHARACTER are supported. Initializers
retain existing constant-expression and assignment-conversion rules, including
named constants and CHARACTER padding/truncation.

## Lifetime and recursion

Each defining procedure owns one value for each saved symbol throughout one
execution. Repeated and recursive calls share that value; unsaved locals,
arguments, results, loop stacks, and expression caches remain activation-local.
Constant initializers are validated before executing the main program and are
applied exactly once per root execution, never on procedure entry. Fixed-length
CHARACTER storage is not blanked by a later or recursive invocation. Distinct
procedures with the same local name retain distinct storage.

The shared store belongs to `execute_program`, not to process-global Fortran
SAVE variables. A second execution of the same immutable IR starts fresh,
including after a previous execution failed. Initialization validation shares
the execution budget. Existing array, CHARACTER, symbol, and call-depth limits
remain unchanged. Merely checking source does not execute a user procedure.

## Effects and aliases

PURE/SIMPLE procedures cannot contain initialized mutable locals or SAVE.
Ordinary functions can read saved state but cannot modify it directly, through
writable actuals, or through a transitive callee. This conservative function
effect restriction is an interpreter boundary, not a restriction of ordinary
Fortran. Subroutines and explicitly IMPURE ELEMENTAL functions can modify saved
state under the existing effect rules. IMPURE ELEMENTAL evaluation retains its
existing once-per-element execution semantics.

Saved actual arguments use checked value-result association. A direct saved
actual may not also be referenced by the callee's transitive call graph. This
includes a recursive call into its defining procedure and prevents stale
copy-back from concealing an update through another access path. The guard is
conservative even for read-only direct actuals. A parenthesized input expression
is a snapshot and remains allowed. Writable actual overlap rules still apply.
Active saved DO control variables are shared and protected across calls, with
RETURN/EXIT cleanup retaining their existing semantics.

## Independent checks and supported boundary

The parser records storage duration. The adapter independently compares it to
the producer's SAVE attribute and declaration initializer, then validates exact
initializer AST identity and converted cached value. Runtime validates saved
symbol ownership, purity, scalar shape, KIND, and declaration metadata before
use; it independently recomputes each constant initializer and CHARACTER length
under the shared budget before accepting the cache. Visibility rules do not
change when a symbol is backed by shared storage.

Uninitialized SAVE, standalone SAVE statements, procedure-local saved arrays, derived values,
POINTER/TARGET/ALLOCATABLE objects, dummy arguments, function results, and
runtime-length saved CHARACTER remain unsupported. Explicit module SAVE remains
unsupported. A later bounded [main-program SAVE extension](MAIN-PROGRAM-SAVE.md)
accepts initialized intrinsic main objects with their existing root storage; it
does not extend procedure-local array persistence. There is no DATA statement or
process-global state API.

## Original utilities and verification

`tests/saved_locals/cases/original_recursive_gen.f90` embeds the original
`gen` (xutilities line 7983, initialized `icomb` at 7990) and `default_logical`
(line 3687) bodies without edits, preserving CRLF bytes and comments. Only the
surrounding module, `default` interface, and driver are new. The driver tests
recursive generation, state retained by a later call, and explicit counter reset.
The runner verifies both whole-source fingerprint and embedded body identity;
`original-source-map.json` records exact byte ranges and hashes.

The 37-case suite passes strict GNU Fortran 2018 comparisons: 17 executed
programs, 11 compile-only subset/safety cases, and 9 source rejections after the
main-program extension promotes the unchanged `main_explicit_save` fixture. Each GNU
compile/run uses a fresh temporary directory and `-pedantic-errors -fcheck=all`.
The native SAVE executable adds 63 adapter/runtime/cache/budget/reset checks.
The unchanged historical `mutable_local_initializer` source now succeeds; the
automatic-array initializer remains rejected with a more specific diagnostic.

At the isolated PURE/SAVE checkpoint, the untouched full
utility source advanced to `assert_le` at 8187:40: the valid dummy identifier
`procedure` was rejected as reserved. The integrated 0.33 contextual-name correction
passes that declaration and reaches the ALLOCATABLE-dummy SIZE bound at 8663:63. This is only the first declaration
blocker, not a claim that every earlier executable body is supported.
