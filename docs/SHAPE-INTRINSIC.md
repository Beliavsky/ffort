# Bounded SHAPE inquiry

`SHAPE(SOURCE[, KIND])` returns a rank-one INTEGER vector containing SOURCE's extents in dimension order. Scalar SOURCE produces a zero-length vector. This milestone covers the interpreter's numeric, logical and character scalar/rank-one/rank-two/rank-three sources and INTEGER result kinds 4 and 8. Keyword order, sections, empty dimensions and runtime dummy/allocated extents are covered.

SHAPE is a descriptor inquiry: it does not require SOURCE element values to be defined. An unallocated allocatable SOURCE is rejected by the interpreter. This does not promise support for an absent optional SOURCE. Dummy association still follows the existing interpreter rules, so the original utility callers initialize their actual arrays.

Constant-expression support is intentionally narrower than the full Fortran standard: parameter array sources and nondummy, nonallocatable, nonassumed, nonautomatic explicit-shape variable names are supported. Do not infer support for every constant array expression, pointer, derived type, higher rank or other integer kind.

## Independent checks

Run `python tests/shape_intrinsic/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran /absolute/path/to/gfortran`.

The runner snapshots the candidate, checks independent literal expected output as well as GNU results, records command output/exit status and SHA-256 hashes, and requires clean stdout and diagnostic behavior on errors. It tests source rejection separately from runtime safety. GNU never executes the undefined-value inquiry fixture and never processes the unallocated-source safety fixture. GNU's support for INTEGER kind 16 is recorded as compile-only, not incorrectly treated as a GNU rejection.

The fixture `original_conform.f90` retains the exact normalized bodies of `conform_real_1d`, `conform_real_2d`, `conform_real_3d`, and `conform_optional_real_2d` from the vendored utility source. `source-map.json` pins source bytes, source line ranges and normalized body hashes; every runner invocation verifies all four bodies before testing. Calls cover matching and mismatching extents plus absent optional arguments.

Native tests are `test_shape_intrinsic_producer` (independent upstream resolved type/rank/kind metadata and shadowing) and `test_shape_intrinsic` (adapter and runtime fail-closed checks after corrupting result metadata, arguments and KIND, including scalar zero-length results, enclosing SUM and KIND queries, nonconstant KIND, invalid source rank/type and overflow-sized forged bounds).

This is a SHAPE milestone, not complete utility-module compatibility or completion of `combine_mat_tensor_real`.

The integrated 0.29 release supports allocated numeric/CHARACTER rank-three SOURCE as well as ordinary explicit-shape and assumed-shape dummy inquiries.
The large-empty-dimension fixture checks all three zero-axis positions with the
other dimensions at the largest supported default-INTEGER extent (2,147,483,647),
without allocating any array elements or overflowing a dimension product.

Semantics follow the [official GNU SHAPE documentation](https://gcc.gnu.org/onlinedocs/gfortran/SHAPE.html).
