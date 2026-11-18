# CHARACTER element LEN specification expressions

Run `python tests/character_len_elements/run_tests.py --candidate /path/to/interpreter --gfortran gfortran`.
The interpreter and strict GNU Fortran runs are independently compared with the
manifest's expected output. Unsafe/runtime-policy fixtures are compile-only in
GNU, never executed. The original `prepend_char` body is copied byte-for-byte
from the supplied utilities source and checked against `provenance.json`.

This bounded extension permits scalar element inquiries through rank three;
it does not permit general specification functions, optional/local subscript
values, or array sections in specification expressions. Executable LEN behavior
is unchanged. See `docs/CHARACTER-PROCEDURES.md`.
