# Independent elementary-math verification

Run `python run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
Either backend may also run alone. The manifest holds independent expected
answers and distinguishes execution, compilation-only and source rejection.
Unsafe overflow/domain inputs and undefined variables are never executed by GNU.

Three complete upstream examples are preserved byte-for-byte and checked against
`upstream.json` before every run. The runner records source hashes, candidate
hash, tool versions, commands' results and the exact classification summary.

See `../../docs/ELEMENTARY-MATH.md` and the two native tests for the bounded
contract, raw-IR corruption tests and independent producer checks.
