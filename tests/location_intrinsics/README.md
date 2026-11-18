# MINLOC/MAXLOC and original `iminloc`

Run the executable and independent GNU Fortran oracle from clean temporary
compiler directories:

```sh
python3 tests/location_intrinsics/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

The manifest distinguishes successful execution, source rejection and runtime
safety rejection. Successful output is checked against fixed expected values and
GNU output independently. GNU compilation-only cases are legitimate Fortran
outside this prototype's supported subset, not claims of GNU execution.

`cases/original_iminloc.f90` retains lines 3822–3828 of the original utilities
unchanged apart from CRLF-to-LF normalization. The module constants and driver are
new wrappers. `source-map.json` records the original file and normalized-body
hashes. The runner verifies those hashes and exact body inclusion before testing.
The driver checks ties, reverse sections and empty input. It is not the original
main program and does not establish support for the complete utilities file.

The remaining fixtures cover numeric kinds 4/8, rank-one/two ARRAY, both DIM
values, scalar and array MASK, result KIND, BACK ties, column-major locations,
nonunit lower bounds, zero-size arrays, all-false masks, parameters, composition,
run-time shape checks, KIND without reading undefined data, and DIMENSION
attributes. Malformed arguments and the execution budget are checked for failure
without leaking PRINT output.

Native tests independently mutate executable IR, verify the strict producer
metadata and check the runtime with and without an evaluating array context.

## Observed GNU 14.2 discrepancy

The `impure_mask_once` fixture combines a rank-two MASK with BACK=.true. GNU 14.2
returns the masked-out location [2,1] for [[4,-1],[2,2]] in element-order notation.
The correct last selected minimum is [2,2]. This case is compiled by the GNU
runner but its GNU result is not used as an oracle. `oracle-discrepancy.json`
retains the separate actual GNU execution, command flags and source hash.
`masked_back_reference` independently computes the expected location with an
explicit Fortran loop and runs under both engines. The interpreter case still
checks all mask side effects and the location against fixed expected output.
This is an observed discrepancy, not a claim about its cause or every GNU version.
