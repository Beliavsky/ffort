# KIND inquiry in REAL selectors

Pinned FortFront commit: `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.
Apply after patches 0001–0013 with `patch -p1` in `vendor/fortfront`.

The declaration selector parser previously passed `kind=expression` directly to
an expression parser, retaining only the identifier `kind` instead of the value
expression. The correction removes that keyword prefix for expression parsing,
while retaining the complete original declaration type text. It links the
selector expression to its declaration so name binding sees the correct scope.
Grouped declarations and the DIMENSION-attribute construction path retain that
same selector field as ordinary single declarations.

The metadata constant evaluator now handles KIND using its argument's resolved
kind, without evaluating its value. Literal metadata can also be computed before
the full annotation pass, which is needed by strict call checks. The strict
dummy-type checker also uses the retained selector AST when textual named-kind
resolution cannot resolve a direct KIND expression. Positive REAL64 and negative
REAL32 actual-argument regressions preserve exact kind checking. Untyped,
homogeneous array constructors retain the exact element type and kind from
their children instead of losing REAL64 information in generic inference.

`test_kind_inquiry_producer` verifies direct positional and keyword KIND
selectors, a constructor argument, and named constants using literals or
undefined ordinary variables. Existing adapter tests cover exact expression
matching and imported kind parameters. These changes do not provide a general
constant-expression evaluator or broaden the supported source grammar to typed
constructors or implied DOs. Typed function headers retain literal/named kind
selectors; direct KIND selectors belong to ordinary REAL declarations.
