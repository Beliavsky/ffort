# Local patch 0009: preserve intrinsic conversion result types and ranks

Upstream: FortFront, https://github.com/lazy-fortran/fortfront, pinned revision
`9a5896a1fce32c394fd02dd1da1bd261ea7a646f`. This local interpreter-project fix
retains the upstream MIT copyright/license in `vendor/fortfront/LICENSE` and
makes no claim of upstream endorsement.

Intrinsic inference correctly selected INTEGER for INT and REAL for REAL, but
subsequent call-signature collection replaced that result with the dominant
argument type. Consequently INT(3.0) became REAL and REAL(3) became INTEGER during
strict argument checking. Later resolved-type annotation corrected the public
metadata but could not undo the earlier erroneous diagnostics. Signature
collection now retains conversion intrinsics' already inferred result types.
The conversion set is INT, REAL, DBLE, CMPLX, LOGICAL and UINT.

The generic inference path deliberately avoids array-in/array-out behavior for
intrinsics because reductions are not elemental. Conversion intrinsics now
explicitly preserve the source array's rank and dimension sizes while replacing
its element type with the conversion result type. Reduction inference remains
unchanged. This correction applies to positional and keyword arguments, not
only to interpreter-specific syntax.

`test/test_keyword_conversion_producers.f90` invokes the strict producer directly.
It checks 22 nested INT/REAL conversions, including named conversion inputs,
conversion-valued function keywords, reductions with conversion-valued DIM,
eight rank-one conversions and two rank-two conversions, and passing converted
arrays to matching assumed-shape dummies. Both inferred and resolved types/ranks
are checked. Four negative cases retain strict rejection of opposite INTEGER/REAL
scalar and array dummies. No diagnostics are suppressed or bypassed.
