# Formatted arrays differential suite

Run from the package root:

    python tests/formatted_arrays/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran

Each passing supported case must pass --check without stdout and execute with
GNU-identical bytes. The unchanged upstream example has processor-dependent
list-directed spacing only on its final integer; that line is compared by token.
Rejected and checked runtime failures must produce no stdout. Results record
source hashes and both implementations' status, stdout and stderr.

`cases/demo_dot_product.f90` is copied byte-for-byte from urbanjost/M_intrinsics
commit fc14233036d910e3678d350efc24609e11475067, example/demo_dot_product.f90.
The license is preserved in UPSTREAM-LICENSE. Other cases are project tests.

The runtime-format milestone promotes the unchanged `dynamic_format` fixture
to byte-exact GNU execution, including ordinary format reversion. Its original
source is preserved; only the manifest expectation changed.

FortFront 0.49 promotes the unchanged `slash_rejected` slash fixture to a successful
full-record GNU comparison. The filename is retained for provenance; it no longer
means rejection. No shipped source generator exists for this historical row.
