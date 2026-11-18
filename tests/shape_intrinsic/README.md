# SHAPE tests

See [the contract](../../docs/SHAPE-INTRINSIC.md). Run `python run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran` from any directory. `--only REGEX` selects cases and `--result NAME.json` selects the report name. An unsuccessful check fails the runner. Expected values are literal, independently specified in `manifest.json`.

`results.json` records the combined GNU/candidate validation. Regenerate it after building a new candidate. All retained utility routines have exact normalized provenance verified before execution.
