# Main-program SAVE regression suite

Run `python tests/main_save/run_tests.py --candidate /absolute/path/to/fortfront-interpreter --gfortran gfortran`.
Run `python tests/main_save/test_runner.py` for the runner self-tests.

The suite preserves complete original demo_minloc and demo_maxloc bytes, with
source/license hashes checked before execution. Both demo_minloc and demo_maxloc execute completely. The historical
`original_demo_maxloc_boundary` name is retained, but its category is success
with GNU execution. All eleven MAXLOC output records use exact integer values,
including exact record counts and final newline; its seven explicitly formatted
records additionally match GNU byte for byte. Successful stderr and check stdout
are required to be truly empty for this promoted case. No source bytes changed.
No fixture generator exists in this suite; the manifest is authoritative. Synthetic cases cover supported
kinds and ranks, constant initialization, scalar expansion, empty dimensions,
CHARACTER padding/truncation, multiple entities, lower bounds, ordinary/recursive
calls, PURE dummy mutation, and legal-but-unsupported versus invalid declarations.

See ../../docs/MAIN-PROGRAM-SAVE.md for lifetime, validation and exact limits.
Every candidate must pass check mode before expected execution. Rejected programs
must emit no stdout. GNU compilations use isolated temporary working directories.
Integer output matching is exact, including INTEGER(8) values above 2**53.
