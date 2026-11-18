# Scalar derived-type regression corpus

Run `python3 tests/derived_types/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
The runner checks compile-only mode, runtime status, expected stdout and requested
error text separately. GNU runs in fresh temporary directories. Undefined-value
and bounded-runtime policy cases are explicitly marked `baseline: skip`; they
are not conformance oracles.

Coverage includes positional structure construction with assignment conversion,
whole-value independence, partial component reads, uninitialized/partial record
rejection, IN/OUT/INOUT copy flags, function results, two distinct same-shaped type
identities, PUBLIC/PRIVATE types and unsupported record syntax. Formatting checks
cover minimum integer digits, quoted text preservation and checked record overflow.

Generated result files record the candidate SHA256. Only successful results from
the final packaged source should be treated as release verification.

0.47 promotes the unchanged `default_component_init_unsupported.f90` source to execution: its defaulted scalar component prints 7. The historical filename and all source bytes are retained.
