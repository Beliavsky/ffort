# ISO_FORTRAN_ENV aliases and kind availability

Run `python run_tests.py --candidate /path/to/fortfront-interpreter --gfortran /path/to/gfortran`.
Either backend can run alone. Run `python test_runner.py` for harness self-tests.
The runner verifies the original upstream file hashes before executing tests.

Four complete unchanged examples pass: COSH, TAN, TANH and EPSILON. See
`upstream.json` and `UPSTREAM-LICENSE` for provenance. The GNU outputs used to
prepare ordinary expected results are independently rerun on every invocation.

REAL128=-1 is the interpreter's explicit unsupported-kind sentinel. The GNU
reference processor supports REAL128=16. The two independent sentinel fixtures
are GNU compile-only in the ordinary runner; `processor-model.json` records the
separate capability comparison without counting it as execution agreement.
Unsupported REAL128 type/literal/conversion uses stay source rejections.

See `../../docs/ISO-FORTRAN-ENV-ALIASES.md` for precise scope and limitations.
