# 0069: MINEXPONENT/MAXEXPONENT model metadata

Apply the matching patch at the vendor/fortfront root after 0068, using
`patch -p1 --fuzz=0`. The verified post-0068 registry has 102 entries; this
patch adds MINEXPONENT and MAXEXPONENT for 104. All earlier entries and metadata
helpers are retained. No numerical execution is delegated to the producer.

Both functions accept REAL and return a scalar default INTEGER. The producer
therefore fixes rank 0 and INTEGER kind 4 independently of operand rank/kind,
including keyword X. Source-bound variable and user-procedure resolution still
precedes intrinsic dispatch. The interpreter separately validates type, shape,
constant-expression eligibility and the documented whole-object inquiry subset.

The frozen standalone semantic delta is exponent-inquiries-vendor-raw.patch,
based on the frozen 0.38 source-test snapshot (registry 91 to 93). Do not apply
it together with this cumulative patch. Reapplying that delta with only the
registry count rebased reproduces this post-0068 snapshot byte-for-byte across
all 457 vendor files.

Focused validation: eight independent producer cases, 63 source cases, 3,754
adapter/runtime/KIND/DAG assertions and 171 native programs pass in the isolated
feature checkout. This is not a claim of a new combined-release build. The
integrator owns the final clean aggregate. Exact replay evidence is recorded in
exponent-inquiries-vendor-replay.json.

References: J3/18-007r1 sections 16.9.126 and 16.9.132,
https://j3-fortran.org/doc/year/18/18-007r1.pdf .
