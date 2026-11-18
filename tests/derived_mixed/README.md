# Grouped derived-component declarations

28 focused sources cover scalar INTEGER/REAL/LOGICAL component lists, each
entity's independent default, undefined siblings, multiple declarations,
constructor override and trailing-default omission, fresh procedure locals,
INTENT(OUT) default reset/undefinedness, constants/kinds and record-copy isolation.
The exact user source prints1000; list-directed numeric padding is not portable,
so that sole case requires a single finite Decimal-equal record. Other successful
outputs are exact, including spacing/newlines. Invalid and undefined-value cases
require exact phase, status, source path, line, column and diagnostic text.

GNU independently executes18 positive programs, compiles4 undefined-value cases
without running them, and rejects6 invalid programs. No undefined value is used
as a GNU output oracle. First candidate results are preserved separately from
strict rerun evidence. Candidate paths and hashes are recorded in each result.

Run generate.py, test_contracts.py, run_gnu.py --gfortran PATH, and
run_candidate.py --candidate PATH. The native companion separately inspects
per-entity roots and mutates adapter metadata; invalid roots are checked by the
runtime independently. The first native draft used unsupported bare ERROR STOP;
its preserved correction adds explicit code1 only.
