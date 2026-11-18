# Combined original COUNT/PACK/RESHAPE utilities

The fixture embeds the exact original true_pos_func, positive_int_vec,
matrix_from_vec and vector definitions. Newline normalization is the only
change inside those definitions. The module wrapper, DP constant and driver
are supplied by this test. `utility-provenance.json` records original-file,
normalized-body and fixture hashes and original line numbers.

The driver composes COUNT-sized results with PACK, RESHAPE, the original
matrix/vector conversion functions, SUM (including both DIM reductions),
DOT_PRODUCT and MATMUL. It also checks nondefault ORDER, reversed sections,
empty inputs, all-false masks and repeated calls whose result sizes change.
Literal expected values in the manifest are independent of both implementations.

Run `python3 tests/count_pack_reshape_integration/run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran`.
GNU comparisons use strict F2018 with bounds/runtime checks. All three new
features must be present. This focused replay does not establish support for
the entire original utilities module.
