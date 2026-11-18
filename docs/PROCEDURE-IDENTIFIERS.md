# Contextual PROCEDURE identifiers

The spelling `procedure` is now admitted in supported identifier slots instead
of being globally reserved by the independent source guard. This covers scalar
and array data, dummy arguments, keyword actuals, function/result names, derived
components, type-bound binding names and imported entity names. Other historically
reserved keywords and intrinsic names are not generally unreserved.

FortFront independently retains the entity's declaration and binding. Vendor
patch 0056 promotes PROCEDURE only after a declaration's type/attributes have
been consumed, recognizes a dummy name before a comma or closing parenthesis,
and accepts it in USE ONLY entity/rename slots and the specific-name list after
MODULE PROCEDURE. The lexer continues to classify PROCEDURE as a keyword. Actual
PROCEDURE declarations, MODULE PROCEDURE clauses and type-bound PROCEDURE clauses
keep their existing parsers and semantic checks. No validation is disabled.

## Boundaries

Program or module units themselves named PROCEDURE remain producer boundaries.
PROCEDURE pointer declarations remain outside the interpreter subset, although
the native producer regression verifies their existing parse and pointer/type
metadata are preserved. General keyword-as-name support, intrinsic shadowing,
new procedure kinds, new pointer behavior and external I/O are not added.

## Unchanged original routine evidence

The supplied `xutilities.f90` routine `assert_le` at lines 8187–8197 is preserved
byte-for-byte, including its CRLF endings, in two synthetic module/driver wrappers.
The routine is 541 bytes with SHA-256
`ba3a41bf620568c70f57ff6121af1eb090d97519328c196b4bc9c50e4854fe12`.
There are no replaced dependencies or edited body statements.

Strict GNU Fortran compiles and executes both wrappers: one checks less-than,
equal, negative values and the keyword actual `procedure=`, and the other verifies
the formatted diagnostic and ordinary STOP for a failed assertion. The isolated
0.32 naming patch originally stopped at `WRITE(*,format)` on original line 8193.
With bounded stdout WRITE and grouped formats, these same bodies now execute in
the interpreter, including the failing assertion's diagnostic. The stop case
checks the interpreter's existing bare STOP notice on stderr separately from
GNU stdout agreement. No source or provenance bytes change. Neither result
claims full utilities execution.

## Verification

`tests/procedure_identifiers/check_provenance.py` verifies original source, routine
and wrapper hashes before the source suite runs. The suite separates safe GNU
execution comparisons, required rejections and byte-preserved original-body cases.
`test/test_procedure_identifiers.f90` checks the dummy's identity, rejects a forged
binding, executes the baseline, inspects the producer's retained dummy and verifies
that a genuine PROCEDURE pointer declaration still has its original type/attribute.
Existing parser, module, generic, keyword-argument and class-binding regressions
are run independently. All pre-existing Fortran test sources remain unchanged.
