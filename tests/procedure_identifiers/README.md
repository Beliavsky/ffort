# Contextual PROCEDURE name tests

Run `python3 run_tests.py --candidate /absolute/path/to/interpreter --gfortran
/absolute/path/to/gfortran`. Safe `run` cases execute with strict GNU Fortran 2018
and runtime checks. `reject` cases retain unsupported or malformed boundaries.

The two original-body cases contain the exact original assert_le routine,
including CRLF endings. With bounded stdout WRITE and grouped formats, both now
execute and agree with GNU output. The failed-assertion driver separately checks
the interpreter's existing `STOP\n` stderr notice. `check_provenance.py` verifies
the unchanged source, body and wrapper hashes. All other fixtures are synthetic.

See `docs/PROCEDURE-IDENTIFIERS.md` for supported slots and remaining limitations.
