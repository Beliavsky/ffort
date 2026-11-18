# Independent PURE/SIMPLE verification

This suite checks the interpreter through its CLI without importing its
implementation. GNU Fortran is an independent oracle, not an execution backend.

## Reproduce

After building the interpreter:

```sh
python3 tests/pure_simple_independent/test_runner.py
python3 tests/pure_simple_independent/run_tests.py --candidate /path/to/fortfront-interpreter --gfortran gfortran
```

The candidate argument is one executable path, including paths with spaces;
the harness never invokes a shell. Each compiler invocation uses a fresh
temporary directory. Each process has a 15-second timeout. `generate_cases.py`
recreates the checked-in source files, weakened reference sources and manifest.

## Coverage and interpretation

The manifest contains 121 cases: 56 successes, 50 invalid sources, 11
standard-valid-but-unsupported programs, and 4 runtime-safety cases. Successful programs have independently specified
numeric/token expectations. Static errors must return 1 with a diagnostic and
no program output, including when the main program contains a preceding PRINT
or the invalid procedure is never invoked. Runtime checks must pass `--check`,
then return 2 and preserve only the expected earlier output. Error termination
and uninitialized reads are interpreter safety checks, not compiler-runtime
conformance claims.

Coverage includes both typed prefix orders and all six PURE/SIMPLE/type orders;
functions and subroutines; scalar OUT/INOUT and rank-two section writes;
constants from hosts/modules; imported and forward callees; intrinsic calls;
ERROR STOP; direct and nested call restrictions in IF conditions, DO bounds,
subscripts and unreachable bodies; I/O; writes through input dummies; SAVE;
initializers; duplicate/conflicting prefixes; and explicitly unsupported legal
features such as recursion, VALUE arguments and internal I/O.

The harness self-tests check finite/tolerant numeric comparison, exact integer
values and token counts, status codes, required diagnostics, output leakage,
source-path diagnostic spoofing, source/reference reproducibility, preservation
of identifiers in lowered references, and invalid-versus-unsupported categories.

## Native SIMPLE compiler limitation

The checked toolchain is GNU Fortran 14.2.0. It accepts the `-std=f2023` option
but rejects a valid SIMPLE procedure header. The runner records both a valid
SIMPLE probe and a forbidden SIMPLE-to-PURE-call probe; rejecting both does not
count as SIMPLE semantic validation. A syntax-only implementation that accepts
both is also not considered a native SIMPLE oracle.

For compilers without the tested native capability, each source using SIMPLE
has a checked-in `pure_references/` copy. Only procedure prefixes change:
SIMPLE becomes PURE, or is removed if an explicit PURE is already present.
Identifiers and procedure bodies remain unchanged. These references test
ordinary calculations and inherited PURE constraints only. They do **not**
verify the additional SIMPLE semantics. In particular, a SIMPLE-to-PURE call
and a SIMPLE mutable-host read must be rejected by the interpreter while their
weakened references compile. Original SIMPLE checks use independently specified
standard-based expectations. This distinction is recorded per case in JSON.

`gnu-baseline-results.json` records baseline-only evidence; `results.json`
records the actual candidate and comparison run when produced. Results include
tool versions, source/reference/manifest hashes, executable hash, capability
probes and complete stdout/stderr/status data. Passing these selected tests does
not establish full Fortran conformance or Windows execution.

## Primary sources and semantic boundaries

[J3/24-007](https://j3-fortran.org/doc/year/24/24-007.pdf), clauses 15.6.2.1,
15.7, 15.8 and 16.1: SIMPLE implies PURE, and calls from SIMPLE require SIMPLE
callees. PURE restricts writes to nonlocal/input data and external I/O, but
permits reading ordinary nonlocal variables. SIMPLE further restricts nonlocal
designators, with an exception for constant specification inquiries. Named
constants remain usable. Pure subroutines may modify appropriate dummy
arguments. Initialization implies SAVE and is disallowed for mutable pure
locals. Internal I/O is permitted by these purity rules; this interpreter
still excludes it. ERROR STOP differs from prohibited ordinary STOP.

C1552 prohibits repeated identical prefixes. C1553 excludes IMPURE with PURE
or SIMPLE, but does not prohibit PURE+SIMPLE together. This agrees with
[J3/23-007r1](https://j3-fortran.org/doc/year/23/23-007r1.pdf) and takes precedence
over the conflicting prefix statement in the earlier informal
[WG5 N2212 overview](https://wg5-fortran.org/N2201-N2250/N2212.pdf).

[GCC 14 release notes](https://gcc.gnu.org/gcc-14/changes.html) describe the
Fortran 2023 flag as preparation for support, not a promise of all features.
[LLVM Flang's support table](https://flang.llvm.org/docs/FortranStandardsSupport.html)
lists SIMPLE as unsupported when reviewed on 2026-11-14. No Flang, Intel or NAG
execution is claimed in this suite.
