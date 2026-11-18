# ELEMENTAL subroutine CALL validation

Upstream: lazy-fortran/fortfront, MIT copyright (c) 2025 Christopher Albert,
revision `9a5896a1fce32c394fd02dd1da1bd261ea7a646f`.

Local interpreter 0.15.0 change, supplied as
`0012-elemental-subroutine-calls.patch` after patches 0001–0011.

The structural `semantic_call_signature_checker` has a second strict CALL
validation route. Unlike the dedicated strict checker, this route omitted the
ELEMENTAL flag when delegating to `validate_call_against_interface`. As a result,
valid array actuals for scalar elemental subroutine dummies were reported as
array-versus-scalar type mismatches. Pass the declaration's preserved ELEMENTAL
attribute to the existing strict element-type check. Ordinary subroutine rank
checks and elemental argument element-type checks remain enabled.

`test/test_elemental_mutable_producers.f90` directly exercises module and internal
CALLs, rank-one/rank-two actuals, IMPURE/ELEMENTAL prefix retention and an invalid
real-array-to-integer-dummy call. The recognizer and fail-closed adapter separately
check conformity, scalar-only dummies, writable actual rank, access and intent.
