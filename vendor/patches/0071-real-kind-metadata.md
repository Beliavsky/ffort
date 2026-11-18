# 0071: REAL conversion KIND metadata

Local MIT-licensed producer correction for REAL(A [, KIND]), developed against
frozen0.39 through0069 and ordered after the independent0070 feature patch.
Apply from vendor/fortfront with patch -p1 --fuzz=0. No registry entry is added.

REAL of INTEGER or REAL without KIND returns default REAL, not the kind of its
argument. Only COMPLEX retains the argument kind when KIND is absent. This
producer rule does not enable COMPLEX in the bounded interpreter. KIND keyword
arguments are resolved by name, including reordered KIND/A association, rather
than being assumed to occupy the second source argument slot.

The interpreter independently validates constant KIND, numeric types/kinds,
rank, shape and cached metadata. Ten strict producer tests independently inspect
resolved type/kind/rank for default, explicit, reordered and parameter KIND,
including rank-three and empty arrays.
