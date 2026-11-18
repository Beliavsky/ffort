# Array-valued function result tests

Run the standalone interpreter and GNU Fortran oracle with:

```
python tests/array_results/run_tests.py --candidate path/to/fortfront-interpreter --gfortran gfortran
```

The manifest distinguishes successful source, compilation rejection and checked
runtime policy failures. GNU `compile` entries establish valid syntax only, not
an independent runtime-policy oracle. Expected outputs are explicit constants,
not copied from whichever compiler was run. `results.json` records both tools,
commands, checks and source hashes. See docs/ARRAY-RESULTS.md for the contract.

The original utility fixture retains six complete procedure bodies unchanged
apart from line-ending normalization. The source is the supplied xutilities.f90
retained in tests/utilities_slices/source/xutilities.f90; provenance hashes are recorded in
original-bodies.json.
