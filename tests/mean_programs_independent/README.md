# Independent KIND, constructors, declaration initialization and random harvest tests

This suite uses independently specified source programs and expected results. GNU
Fortran is an oracle, never a backend for the interpreter. Compiler subprocesses
run in fresh temporary directories, preventing unrelated module files from being
picked up accidentally. No shell is used by the runner.

Run from any directory with Python 3:

```sh
python3 generate_cases.py
python3 test_runner.py
python3 run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran /absolute/path/to/gfortran
```

`--only REGEX` selects cases; `--result filename.json` chooses a report relative to
this suite directory. Original-source SHA-256 digests, candidate binary digest,
compiler flags, tool versions, exact stdout/stderr, status and independent
expectations are saved. Tests require successful `--check` to produce no stdout;
source rejection must occur without any program output. Runtime-policy failures
must preserve only explicitly expected earlier records and return exit status 2.

## Coverage

- Both original user programs are reproduced verbatim, including spacing and
  line breaks, as `user_exact_mean_initialized.f90` and
  `user_exact_mean_random.f90`. The former must print 20; the latter must print a
  finite value in [0, 1). Their originating message IDs are retained in the
  manifest for provenance. They are not rewritten into easier examples.
- KIND checks scalar and array metadata, default integer/logical/character and
  real32/real64 kind values, parameters, undefined operands, invalid arguments,
  and type-only inquiries that must not execute function bodies or read data.
- Array constructors check bracket and slash syntax, same-type/same-kind items,
  scalar and array items, nesting, empty array items, conversions at assignment,
  overlap, runtime sections, calls, intrinsic composition, impure evaluation
  order, malformed source and unsupported nonempty typed forms. The
  byte-preserved typed-empty historical fixture now succeeds and prints zero.
- Declaration initializers check rank-one constructor values, scalar expansion
  to rank one/two, lower bounds, empty arrays, parameter expressions, multiple
  declarators, mutation, kind precision, invalid ranks/extents/constant values,
  and rejection of unsupported array parameters and saved procedure locals.
- RANDOM_NUMBER checks writable real32/real64 scalars, whole arrays, elements,
  reversed/strided/rank-reduced sections, column-major ordering, keyword calls,
  OUT/INOUT association, impure elemental calls, empty destinations, preserved
  sentinels/undefined unselected elements, invalid targets and pure-procedure
  calls, checked bounds/stride/work failures, unsupported RANDOM_SEED, and fail-closed rejection of user procedures named
  RANDOM_NUMBER (a reserved name in this subset).

## RNG oracle boundary

GNU and interpreter random sequences are **never compared with one another**.
`R` expectation tokens require one finite numeric output in [0,1). Every expected
output value is accounted for, including unselected sentinel elements.

Each 4096-value distribution smoke test separately checks finite range, mean
between 0.4 and 0.6, variance between 0.04 and 0.12, broad quartile coverage and
more than 1024 distinct values. These intentionally loose checks catch constants,
wrong ranges and badly broken distribution implementations; they are not a proof
of randomness or an attempt to certify a pseudorandom generator. They have no
fixed reference sequence, and GNU outputs are allowed to differ each run.

The interpreter documents a reset seed for each execution. Only interpreter runs
therefore have repeatability assertions. Candidate-only metamorphic checks ensure
that scalar, vector and matrix calls traverse the same stream; reversed and
strided destinations receive that stream in section element order; empty calls
and KIND's type-only inquiry do not consume random values. These tests make no
claim about GNU seed state or cross-compiler reproducibility. No RANDOM_SEED
functionality is presumed or emulated.

## Categories

`success` cases execute and compare expected output. `invalid` cases are rejected
by both compilers. `unsupported` cases are legal Fortran accepted by GNU but
outside the documented interpreter subset. `runtime` cases check the interpreter's
safety rules; GNU is only used for syntax where execution would read undefined
values or rely on the prototype's deterministic policy. `baseline=skip` explicitly
marks safety cases for which no GNU comparison is claimed. Exact compiler
accounting is in each generated result's summary.

Regenerate fixtures before using this suite with a changed generator.
`test_runner.py` checks deterministic regeneration, strict output accounting,
finite numeric parsing, diagnostic checks, RNG assertions and category separation.

## Explicit REAL selector boundary

The release retains literal and named-parameter REAL kind selectors and adds a
**direct KIND inquiry** in a selector. Tests cover positional/keyword syntax,
undefined scalar/array operands, constructor operands, and explicit procedure
dummy/result declarations. Typed function headers retain literal/named selectors;
the direct-KIND header fixture is preserved as an unsupported GNU-valid case.
General arithmetic and other intrinsic function expressions used directly as REAL
selectors remain outside the supported subset. Their original legal Fortran
fixtures are retained, compiled with GNU and required to be rejected without
program output by the interpreter. They are recorded as `unsupported`, not as
invalid Fortran or as successful feature cases. Arithmetic and supported intrinsic
expressions can still compute an INTEGER PARAMETER before using its name as a
REAL selector. This boundary was made explicit during independent review; no
source fixture was removed to hide a failure.

The historical `constructor_unsupported_implied_do` filename is retained, but its unchanged body now succeeds (empty stdout) under both interpreter and GNU. Generator and manifest both record success.
