# 0037: Explicit opt-in for allocatable intrinsic assignment

Local compatibility patch against the bundled FortFront source. Upstream authors
are not represented as authors of or endorsers of this interpreter-specific work.
The existing upstream license and copyright notices remain unchanged.

The upstream strict semantic mode diagnoses differing literal assignment lengths
for an allocatable array as prohibited automatic reallocation. Standard Fortran
permits that operation, and this interpreter now implements it with bounded,
overlap-safe storage. Switching all analysis to inference mode would relax
unrelated checks, so this patch instead adds a default-false frontend option,
`allow_allocatable_reallocation`.

The option is copied to the semantic context and preserved by the context's
explicit initialization, assignment, deep-copy and clone operations. When true,
only `validate_strict_allocatable_lhs_reallocation` is skipped. Every other strict
check is unchanged. The interpreter opts in explicitly in `fi_frontend`; consumers
that do not request it retain the prior strict-mode behavior.

`test/test_allocatable_reallocation_option.f90` verifies default rejection,
opt-in acceptance and rejection of an undeclared reference with the option on.
The focused `tests/allocatable_assignment` suite verifies execution against GNU
Fortran as well as interpreter-only allocation/initialization safety checks.

Apply from `vendor/fortfront` with `patch -p1 < ../patches/0037-allocatable-reallocation-option.patch`.
