# Standalone normal-mixture validation suite

This suite contains the complete supplied normal-mixture EM program, a minimal
ACOS-enabled variant, deterministic synthetic drivers, and independent Python
validation. It does not require files outside this release tree.

## Maintained input and provenance

`input/xmix_dt.f90` is the unchanged supplied attachment:

- Bytes: 5,553
- SHA-256: `bb96142295269f67e2e34a95ad708db957b75b96ab174219690d4da7814f1f4d`

`sources/xmix_dt_original.f90` is an exact copy. The only changes in
`sources/xmix_dt_acos_variant.f90` are activating
`real(dp), parameter :: pi = acos(-1.0_dp)` and commenting out the numeric PI
parameter. The exact two-line change is maintained in `acos_variant.diff`.

The other 25 sources are explicitly labeled synthetic main programs. Each starts
with the byte-identical module prefix from the original attachment. These are
separate tests, not substituted originals or source-reduction evidence.

`source_manifest.json` records relative paths, byte counts, hashes, the unchanged
module-prefix hash, and each synthetic driver's data and expected error contract.
The original input is user-supplied test material; this suite makes no new license
claim for it. The harness and synthetic drivers are original work for this task;
no third-party implementation was imported.

Running the suite verifies all maintained input, source, diff and manifest bytes.
Missing generated files can be created. Existing files with differing bytes cause
an immediate failure and are never silently overwritten. An intentional fixture
change requires reviewing and maintaining its source and metadata together.

## Commands

From the repository root, using GNU Fortran available on PATH:

```
python3 tests/normal_mixture/test_runner.py
python3 tests/normal_mixture/run_tests.py --prepare-only
python3 tests/normal_mixture/run_tests.py --candidate /path/to/fortfront-interpreter
```

The default invocation runs both GNU and the candidate. Use `--gfortran` to select
an explicit GNU executable, `--repeats` to change the default six full executions
per source per engine, and `--result` to select the summary JSON destination:

```
python3 tests/normal_mixture/run_tests.py \
  --candidate /path/to/fortfront-interpreter \
  --gfortran /path/to/gfortran --repeats 12 --result results/normal-mixture.json
```

GNU compilation always uses:

```
-std=f2018 -pedantic-errors -fcheck=all -fbacktrace -Wall -Wextra
```

Omitting `--candidate` runs the GNU side only. `--skip-gnu` runs only the candidate
against the independent invariants and mathematical checks; it is not fresh GNU
differential evidence. `--original` accepts another location for the same known
attachment bytes, not an arbitrary replacement program.

`--prepare-only` and `test_runner.py` execute no GNU compiler or FortFront program.
The latter consists of 21 pure-Python self-tests, including mocked subprocess
failures. The final staged suite passed these self-tests; candidate execution
must be recorded against the merged executable before claiming a release pass.

## Budgets and evidence

For each complete source the candidate first runs once with its ordinary default
budget. That attempt is recorded separately as either a successful complete run,
expected step-budget exhaustion, or an unexpected failure. A step-limit outcome
is not presented as a completed original-program execution.

Repeated full runs then use the existing explicit CLI budget:

```
fortfront-interpreter --max-steps 100000000 input/xmix_dt.f90
```

The suite's `--max-steps` option changes this explicit bound; it defaults to
100,000,000. It does not change interpreter limits or edit the input source.
The 25 smaller synthetic drivers continue to use the interpreter's default
budget. Check-only invocations must succeed before runtime tests are attempted.

GNU executables and module files are compiled and run in per-fixture children
of a fresh temporary directory, which is removed after the run. Evidence retains
only JSON, stdout and stderr files, never generated executables or modules.

Reports under `evidence/<label>` record exact commands, candidate binary hash,
compiler version, source manifest, stdout/stderr, elapsed time and outcomes.
Unexpected default-budget failures cause the runner to fail, even if a later
larger-budget run succeeds. Exit statuses, signals, timeouts, launch failures,
wrong or absent error messages, and output leaks are checked explicitly.

## Full stochastic program

GNU and FortFront random streams are not compared. No fixed output, matching
iteration count, or repeatable sequence from no-argument RANDOM_SEED is assumed.

Hard checks verify all seven lines, headers, the observation count, iteration
bounds, L1 convergence field, F16.3 likelihood width, I3/6F11.4 component widths,
unchanged true parameters, finite values, positive weights and SDs, and normalized
weights within displayed precision.

Separate broad stochastic smoke bounds require convergence and plausible fitted
component weights, means, SDs, likelihood, mixture mean and mixture variance.
Estimated components are sorted by mean for these checks, allowing label swaps.
These are generous probabilistic sanity checks, not deterministic equality or a
goodness-of-fit proof; an extremely rare random sample can fail them.

## Deterministic synthetic drivers

Twelve successful cases cover:

- A one-component fit with exact mean 0, variance 2 and log likelihood
  `-5/2 * (log(4*pi) + 1)`.
- Default convergence and iteration caps 1 and 2, including final-likelihood
  recomputation after the last update when convergence is false.
- Symmetric components, weight normalization, reversed component labels and
  the explicit variance floor.
- An asymmetric sample at iteration caps 1, 2, 5 and 10 and at convergence.

Independent Python EM equations check expected iterations, convergence, all
returned parameters, and monotonic reference likelihood. The returned likelihood
is also recomputed from the fitted parameters. Synthetic output dimensions,
field widths and precision are checked.

Thirteen expected ERROR STOP cases cover invalid sample/component counts,
parameter shapes, EM options, constant samples, zero starting weight or SD,
empty fitted components and invalid simulation sizes, weights or SDs. GNU must
report its error status 1; the interpreter must report checked-runtime status 2.
The expected message is required, with no stdout. Signals, other exits and
missing diagnostics do not count as successful rejection.

This tests the supplied finite-input algorithm. It does not establish arbitrary
NaN/infinity robustness, global optimality of EM, or unrestricted Fortran support.
