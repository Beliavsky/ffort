# COUNT and PACK integration

The fixture preserves the original true_pos_func and positive_int_vec bodies,
with LF normalization only. It checks positive selection, zero-sized results,
all-false masks, reversed-section actuals, repeated and nested calls, and use
of a returned array as a later function argument/mask.

Run `python3 tests/count_pack_integration/run_tests.py --candidate /path/to/interpreter --gfortran /path/to/gfortran`.
Both COUNT-dependent result bounds and PACK must be enabled. The source and
procedure hashes are in utility-provenance.json; full utilities-module support
is not claimed.
