# 0081: Output implied-DO parent links

Local MIT-licensed producer correction. The existing implied-DO factory now
links every ordered object and start/end/optional-step expression to its control
node. The containing PRINT/WRITE factory already links that node to the statement.
This preserves nested scope lookup, array element classification and declared
intrinsic-name shadows without weakening independent source binding checks.
No grammar or intrinsic registry entries are added.

Apply with `patch --fuzz=0 -p1` at the cumulative vendor root. The interpreter
admits output-only control trees under its separate bounded contract. Constructor
and input implied-DOs remain unsupported. Direct producer tests verify nested
objects, controls, parent links and scalar array-element metadata.
