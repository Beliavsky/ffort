# OPTIONAL numeric and logical array verification

Run independently of fpm's test wrapper:

```
python3 tests/optional_numeric_arrays/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran /absolute/path/to/gfortran
```

The runner checks CLI check/run statuses, silent check mode, diagnostic presence and output leakage. Each GNU compilation uses a fresh temporary directory with `-std=f2018 -pedantic-errors -fcheck=all -O0`; GNU is solely an oracle, never an interpreter execution backend. JSON results record executable, manifest and fixture hashes and complete subprocess results.

Success cases exercise INTEGER(4/8), REAL(4/8), default LOGICAL and ranks one/two: omitted/present forwarding, keyword association, reverse-stride sections, nonunit bounds, empty arrays, mutable INOUT/OUT, and undefined-array metadata. Numeric allocatables cover absence, unallocated association, forwarding to allocatable/nonallocatable OPTIONAL dummies, descriptor bounds, mutation and OUT deallocation. Generic calls cover type/kind/rank dispatch. Logical allocatables remain a source rejection boundary, independently accepted by GNU.

Undefined reads, absent use, absent-to-required forwarding and overlapping writable arguments are interpreter safety tests, not valid GNU differential executions. They explicitly use `baseline: skip`.

`original_utilities.f90` wraps four byte-exact routines from `../utilities_slices/source/xutilities.f90`: `set_optional_alloc_real`, `set_optional_alloc_int`, `set_alloc_real_vec`, and `set_alloc_int_vec`. The last two are the actual source names beneath the `set_alloc` generic. CRLF bytes, prefixes, comments and bodies are preserved; only the enclosing module/interface and caller are new. `utility_provenance.json` holds SHA-256 hashes verified against original and fixture on every run. The integer routine's recursive/PACK branches remain unchanged, although the wrapper invokes its unfiltered branch. No source substitutions are made.

The checked-in Fortran fixtures and manifest are the canonical test inputs.

## INDEX extension

Additional rank-one/two tests cover OPTIONAL LOGICAL array BACK with array STRING or SUBSTRING, omitted and present BACK, empty arrays, and rejection of reading an absent BACK expression or inferring shape from absent BACK with scalar strings. Two present-BACK scalar-string cases are candidate-only specification tests: GNU Fortran 14.2.0 crashes during compilation with an internal compiler error. Their manifest entries state this distinct reason; no GNU run is claimed. `docs/verification/0.27.0/optional-array-index-gnu-ice.json` preserves both compiler failures without mixing in a development interpreter result. The main results.json records supported GNU checks.

The byte-exact combined original utility slice is an explicitly documented rejection boundary: its integer callee requires an unsupported `pure recursive` prefix and recursive calls (its PACK expressions are preserved). GNU compile acceptance is checked; candidate rejection must identify `recursive`. This does not claim implemented integer utility support. The separate real-only original slice executes unchanged on both implementations, without helper substitution.
