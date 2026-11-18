# GNU14 degree-tangent observations

near_pole.f90 records runtime and literal calls at the adjacent REAL8 values on
either side of 90 degrees, plus an explicit complementary-angle calculation.
GNU14.2 returns +/-3.5301143212171575e15 for direct calls, compared with
+/-4.0318320510159320e15 for the complementary form. A separate Decimal reference,
using 110 digits and a Machin-series pi, verifies the latter rounded value.
The same probe shows REAL4 runtime TAND(-0) losing its negative sign while the
literal constant call retains it. Both observations reproduce at -O0 and -O2.

The interpreter's bounded contract uses accurate degree reduction and preserves
zero signs. These two specific source cases are GNU compile-only, not execution
agreements. Other cases retain explicit strict or scoped numerical comparisons.
No claim about the compiler's source-code cause or universal Fortran zero-sign
requirements is made. record_probe.py can refresh the full commands, version,
source hashes and outputs in gnu14-receipt.json using chosen compiler/candidate
paths; it independently checks candidate values before writing the receipt.
