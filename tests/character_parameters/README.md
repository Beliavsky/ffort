# Inferred-length CHARACTER parameters and ASCII conversion

Run `python tests/character_parameters/run_tests.py --candidate PATH --gfortran gfortran`.
The manifest specifies expected output independently of either compiler. Selected
formatted outputs are compared byte-for-byte to catch padding and length loss;
other outputs compare tokens. GNU is a differential oracle, not the source of
expected results. Runtime-policy errors are GNU compile-only, never executed.

The suite covers per-entity inference, prior parameters, TRIM, concatenation,
MERGE, typed and untyped constructors, rank-one/rank-two parameters, scalar
expansion, sections, RESHAPE, zero-sized typed arrays, empty strings, fixed-length
regressions, and the unchanged declaration at xutilities.f90 lines 499–504.
CHAR/ACHAR cover kind-4/kind-8 INTEGER arguments, scalar/rank-one/rank-two values,
optional KIND, ASCII endpoints, empty arrays, invalid constant codes and invalid
runtime codes. Default CHARACTER kind 1 and code range 0:127 are interpreter
policy: GNU accepting another kind or a code above 127 is not interpreted as a
candidate feature requirement.

Native tests `test/test_character_parameters_frontend.f90` and
`test/test_character_parameters_runtime.f90` independently check inferred lengths
and cached parameter values, then corrupt metadata to exercise adapter and
runtime rejection boundaries. `test/test_character_parameters_producer.f90`
independently checks vendor CHAR/ACHAR type/kind/rank metadata and both entities
in declarations containing nested keywords, logical literals, and typed empty
constructors. These run through FPM's auto-test discovery.
No general LEN intrinsic is required by this suite.

## Zero-sized concatenation oracle caveat

`empty_concat_element_length` independently expects element length4 for a
zero-sized length-3 array concatenated with a length-1 scalar. GNU Fortran14.2
incorrectly retains length3, causing a strict compile rejection when a matching
length-4 RESHAPE PAD is provided. This is explicitly classified as a known GNU
compile defect, not a differential execution pass or an invalid source. If a
future GNU compiler accepts the source, its execution must match the independent
expected output. All other unexpected compiler failures remain failures.

[GNU-EMPTY-CONCAT.md](GNU-EMPTY-CONCAT.md) records the exact source, commands,
outputs, version and primary standard reference. Empty-array size comparisons
remain genuine differential tests; they do not establish agreement on length.
