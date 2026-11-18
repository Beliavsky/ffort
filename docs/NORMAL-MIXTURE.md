# Complete normal-mixture EM program

The standalone suite in [`tests/normal_mixture`](../tests/normal_mixture/README.md)
retains the complete supplied `xmix_dt.f90` program and verifies its source hash.
The ACOS variant differs only by activating the supplied commented-out PI
expression and commenting out the numeric PI constant. Both complete sources are
kept separate from the 25 explicitly synthetic validation drivers.

Run the self-tests and original-program suite with:

```
python3 tests/normal_mixture/test_runner.py
python3 tests/normal_mixture/run_tests.py --candidate /path/to/fortfront-interpreter
```

GNU Fortran is found on PATH or selected with `--gfortran`. The suite builds the
supplied programs with strict Fortran 2018 and runtime checking. Full stochastic
outputs are checked using formatting, finite-value, normalization and broad
statistical invariants, not by equating random streams. Deterministic fixtures
supply analytic one-component expectations, independent EM equations, final
likelihood recomputation, variance-floor and error-path checks.

The ordinary default-budget attempt is recorded separately. Full repeated runs
use the existing bounded command-line option `--max-steps 100000000`; synthetic
cases retain the default. Exhausting the default budget is not a full-program
pass. No source/resource limit is changed by this suite.

Every execution report records the actual candidate binary hash and exact
commands. Run against the merged release executable before claiming integrated
success. The suite is a finite-input numerical and language-feature regression,
not proof of global EM optimality or unrestricted Fortran support.

## Running the supplied file

For the Windows invocation reported with the input file, use:

```bat
ffort.exe --max-steps 100000000 ..\xmix_dt.f90
```

The same option is accepted by the `fortfront-interpreter` executable name. The
original source needs no edits. To exercise the supplied ACOS expression, activate
that PI declaration and comment out the numeric PI declaration, as recorded in
`tests/normal_mixture/acos_variant.diff`.

The final clean 0.40 executable has SHA-256 `d24c71b312587ebce987753fff6ad42cb931d5b98bd527d70b2ef5665643f342`.
Both complete variants pass the 128-check acceptance suite, including fresh GNU
compilation/execution and independent deterministic EM checks. Full stochastic
outputs are assessed independently for each random stream; fitted numbers and
iteration counts are not equated across processors.

The separate default-budget trials for both variants exit with checked-runtime
status 2 and empty stdout at line 61, column 33: `execution step limit exceeded`.
The default remains 1,000,000 steps. The explicit 100,000,000-step runs complete;
no default budget, array size or source limit was increased. The preview result
is retained as `tests/normal_mixture/preview-results.json`; release verification
writes a fresh `results.json` for the actual final executable.
