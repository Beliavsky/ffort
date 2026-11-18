# TARGET declarations

See `../../docs/TARGET-ATTRIBUTES.md` for scope and limitations. This suite verifies
the TARGET declaration milestone, not pointer association or original get_data.

`run_tests.py` uses explicit CLI paths and fresh GNU compilation directories.
The manifest distinguishes GNU execution, compile rejection, and compilation-only
of legal-but-unsupported POINTER syntax. Candidate negative cases must fail both
checking and execution without leaking stdout. Result JSON includes the manifest,
source hashes, binary hash, output, exit status and compiler version.
