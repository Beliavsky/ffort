# 0076: Explicit typed empty array metadata

Local MIT-licensed, bounded producer correction. Empty INTEGER, REAL and LOGICAL
constructors have no elements from which to infer type/kind. Their resolved
metadata now reads the explicit type specification and resolves its selector at
the constructor's lexical occurrence, using the existing scope-aware kind resolver.
It records rank one even with zero elements. CHARACTER and nonempty constructor
metadata are untouched. The intrinsic registry remains byte-identical: 106 names.

The interpreter independently admits only the contract in
`tests/typed_empty_arrays/README.md`; producer metadata is not permission for other
source syntax or kinds. Apply this patch with `patch --fuzz=0 -p1` at the cumulative
vendor root. It is independent of 0074/0075. The raw vendor patch supplied for
integration already includes this source change; do not apply it twice.
