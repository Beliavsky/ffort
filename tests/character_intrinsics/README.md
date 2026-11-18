# CHARACTER search, trim and adjustment

Run the portable runner from this directory or the repository root:

```sh
python3 tests/character_intrinsics/run_tests.py --candidate PATH_TO_INTERPRETER --gfortran gfortran
```

`manifest.json` separates executable cases, source rejections and runtime-only
safety checks. `source-map.json` retains the exact original xutilities `quote`
body with source line bounds and hashes; the runner verifies it before testing.
The original source itself is not modified or replaced by these fixtures.

Coverage includes INDEX's search directions, empty strings/substrings, absent
OPTIONAL BACK forwarding, keyword permutations, INTEGER(4/8) KIND selectors,
rank-one/two conforming/scalar operands, sections, dynamically shaped dummies,
empty arrays, constant folding, KIND/LEN inquiries without reading undefined
data, exact blank handling, bounded LEN_TRIM-based result lengths, and all four new
intrinsic names shadowed by scalar/array declarations, function results, user
procedures or a named generic.

The valid `dynamic_empty_descriptors` fixture triggers a GNU Fortran 14.2 compiler
ICE (exit 4) during compilation. The runner records that exact known diagnostic
separately and checks the interpreter against independently specified output.
Other success fixtures execute under GNU; unsupported-kind and undefined-value
cases compile only, never execute as a GNU oracle.

See [the support contract](../../docs/CHARACTER-INTRINSICS.md).
