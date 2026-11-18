# MINLOC/MAXLOC metadata

Teach the strict producer metadata query that MINLOC/MAXLOC return INTEGER,
with default kind 4 or an explicit constant KIND, rank one without DIM and
ARRAY rank minus one with DIM. The producer resolves DIM and KIND by keyword
or positional overload independently of the interpreter's compact argument slots.
Apply after the 0.22 vendor patch set. This does not relax strict compilation or
add an execution backend. `test_location_producer` checks seven metadata cases;
the interpreter independently enforces the documented numeric rank-one/two subset.
