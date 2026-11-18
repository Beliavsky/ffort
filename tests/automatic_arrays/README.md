# Automatic-array checks

Run `python tests/automatic_arrays/run_tests.py --candidate PATH --gfortran PATH`.
The candidate path is a single executable path; no shell is used. Compiler runs
use isolated temporary directories and `-std=f2018 -pedantic-errors -fcheck=all`.
The manifest supplies independent expected values and rejection contracts.

Current coverage: 38 cases, including 17 executed GNU comparisons, three
compiler-accepted subset boundaries, seven compiler rejection comparisons and
eleven interpreter-only safety cases. Resource-exhaustion, undefined-read and
arithmetic-error probes are not run as potentially dangerous compiler programs.
Every negative requires a diagnostic and the expected output (normally empty).

`utility_true_positions.f90` copies the original `true_pos_count` body with only
newline normalization. The wrapper is adapted from the original scratch-array
pattern and does not use allocatable output. See `utility-provenance.json`.
The unchanged utility bodies in the array-result suite give additional combined
coverage, including the `ysum(size(xx))` local array in `growing_mean_vec`.

See `docs/AUTOMATIC-ARRAYS.md` for the exact supported subset and resource policy.
