# Release 0.25 cross-feature checks

These newly written fixtures combine inferred-length CHARACTER scalar/array constants,
CHAR/ACHAR, dynamic-length array results, nested assumed-shape forwarding, empty
array length descriptors, trigonometric constant/runtime expressions and formatted
array output. Successful output bytes must match independently specified expected
values and GNU Fortran. A GNU-compilable dynamic-length PARAMETER remains an explicit interpreter boundary.
These are synthetic integration tests, not complete original upstream programs.
