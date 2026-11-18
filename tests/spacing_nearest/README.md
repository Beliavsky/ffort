# SPACING and NEAREST focused verification

Run `python tests/spacing_nearest/run_tests.py --candidate PATH --gfortran gfortran`.
Run `python tests/spacing_nearest/test_runner.py` to verify the comparison harness.

47 cases include the unchanged upstream `demo_spacing`, precision/kind boundaries,
68 exact logical boundary checks, rank0–3 arrays, mixed-kind and reordered keyword
arguments, empty arrays, optional/pointer/allocatable operands, impure elemental
call counts, source rejections and safe runtime failures. GNU executes25 valid cases. The manifest distinguishes
execution, compile-only policy cases and required compiler rejection. Invalid
zero-direction and outward-HUGE executions deliberately have compile-only GNU
baselines. GNU's behavior outside NEAREST's nonzero-S domain is not an oracle.

Near-zero comparisons use zero absolute tolerance. The numerical boundary program
uses exact Fortran logical comparisons, including signed-zero checks with SIGN.
Original source and upstream license are preserved byte-for-byte; provenance is
in `upstream.json`. No existing historical source fixtures were edited.
