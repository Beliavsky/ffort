# 0039: CHARACTER procedure expression and result metadata

Local compatibility patch against the bundled FortFront source. Upstream authors
are not represented as authors of or endorsers of this interpreter-specific work.
The upstream license and copyright notices remain unchanged.

The canonical type resolver now handles intrinsic CHARACTER concatenation using
the operand kind and maximum rank, including scalar/array expressions in either
order. Function results first consult their explicit result declaration, which
carries rank and type even when provisional inference still says scalar REAL.
The strict actual-argument checker consumes canonical CHARACTER type and rank
rather than that provisional inference. Assumed-length CHARACTER declarations
carry an explicit unknown-length marker, so the strict matcher accepts differing
actual lengths for those dummies. Scalar CHARACTER type compatibility permits
a longer actual to provide a shorter dummy view; the interpreter retains its
shorter-actual and writable-length association checks. Rank, element-type and
CHARACTER-kind checks remain active; fixed-length array matching is not relaxed.

The CHARACTER type-spec parser captures the complete positional length expression
instead of dropping leading signs or stopping after the first number. LEN and
KIND introduce named selectors only when followed by `=`; `character(len(x))`
therefore retains the intrinsic call. Existing nested-token collection is reused.

`test/test_character_producer.f90` covers canonical rank/type, nested array-valued
results, typed constructors, wrong-rank/wrong-type rejection and exact preserved
length expressions. The interpreter's `tests/character_procedures` fixtures
exercise the corresponding independent adapter checks and runtime evaluation.

Apply from `vendor/fortfront` with
`patch -p1 < ../patches/0039-character-procedure-metadata.patch`.
