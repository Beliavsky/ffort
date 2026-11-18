# Local patch 0010: PURE/SIMPLE procedure designation

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. This local interpreter-project patch
retains the upstream MIT copyright and full license in `vendor/fortfront/LICENSE`.
No upstream endorsement or full upstream SIMPLE implementation is claimed.

Procedure-prefix recognition in the lexer, module/program scanners, parser
entry points and declaration helpers now includes SIMPLE. The AST keeps SIMPLE
as its own prefix. Existing purity classifiers include SIMPLE's implied purity;
no SIMPLE source is rewritten to PURE. Existing strict semantic checks remain
active. Code generation/standardization helpers classify implied purity
consistently, although interpreter execution does not use those paths.

The typed-function lookahead and signature consumer now retain attributes after
the result type. Previously, a main-program internal `integer pure function`
(or the newly recognized SIMPLE form) could lose the attribute while a module
procedure followed a different path. Both positions and redundant PURE SIMPLE
permutations are checked. The native direct-producer regression covers module
functions, a module subroutine and an internal-main typed function, verifies
that the keyword is still SIMPLE, and checks inherited output rejection.

The interpreter's recognizer and adapter enforce the additional supported
SIMPLE rules, including simple-only calls and immutable nonlocal bindings.
This patch alone does not implement all SIMPLE constraints in standalone
FortFront. See `docs/PURE-SIMPLE.md` for exact scope and primary references.

Apply after patches 0001-0009, from the interpreter root, with `patch -p1`.
