# GNU 14.2 narrow-result rounding observation

The retained probe compares three forms with ordinary finite REAL(8) inputs:
AINT/ANINT directly requesting REAL(4), literal constant calls, and an explicit
REAL(4) assignment after rounding at the input kind. At both `-O0` and `-O2`,
GNU runtime direct calls give AINT(1.999999999999d0,4)=2 and
ANINT(0.499999999999d0,4)=1. Its constant calls give 1 and 0, respectively.
The round-then-assign form agrees with those constants and the interpreter.
The final results 1 and 0 are exactly representable in REAL(4).

The argument is truncated/rounded before selection of the result representation;
KIND selects the result kind. See the primary GNU descriptions of
[AINT](https://gcc.gnu.org/onlinedocs/gfortran/AINT.html) and
[ANINT](https://gcc.gnu.org/onlinedocs/gfortran/ANINT.html).
No compiler-source cause is asserted here. The observations are recorded with
exact source hashes, compiler version, flags, commands and all outputs in
`gnu14-receipt.json`.

The ordinary source suite classifies this runtime boundary as GNU compile-only
and uses independent expected candidate results. It retains the constant case
and the other normal, tiny, huge and kind-changing cases as strict executions.
These discrepancy outputs are not accepted as alternate correct answers, and no
ordinary comparator tolerance is changed.
