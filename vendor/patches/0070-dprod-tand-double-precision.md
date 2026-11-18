# 0070: DPROD/TAND metadata and DOUBLE PRECISION spelling

Local MIT-licensed changes after certified 0.39 (through patch0069). The registry
adds DPROD and TAND, increasing its count from104 to106. DPROD preserves elemental
rank but fixes its result to REAL8; TAND preserves the REAL operand kind/rank.
No intrinsic names become reserved. Keyword/type/rank identities are checked
independently by the adapter and runtime.

Producer declaration and procedure-prefix dispatch recognizes both DOUBLE
PRECISION and DOUBLEPRECISION as existing REAL8 spelling, including continued
comments and module/procedure contexts. Explicit selectors, DOUBLE COMPLEX and
new kinds are not admitted. Contextual handling preserves DOUBLE, PRECISION and
DOUBLEPRECISION as declared variable, array, dummy and function names. Unmarked
logical newlines and misspellings remain errors. Tests distinguish these spelling
changes from intrinsic implementation and unsupported derived-component KIND.

Apply the matching patch with `patch --fuzz=0 -p1` at the vendor root of certified
0.39. The interpreter core patch contains these raw vendor changes; do not apply
both to the same vendor tree. Subsequent registry patches must retain both names
and adjust the cumulative count.
