# NORM2 scalar expansion correction

FortFront interpreter 0.45 incorrectly passed an enclosing array element position into the scalar NORM2 result index check. For example, `[1.,2.] + norm2([3.,4.])` checked successfully but stopped at its second element with `TRANSPOSE/NORM2 result index outside bounds`.

The correction normalizes only a scalar NORM2 result's local index to one. It applies both to a whole-array reduction and to a DIM reduction of a rank-one input. Array-valued NORM2 and TRANSPOSE retain their actual element positions and all existing metadata, shape and index validation. No numeric algorithm, supported kind/rank, array limit or default step limit changes.

The separate `tests/norm_scalar_expansion` suite covers both operand orders, unary and nested uses, enclosing arrays of ranks one through three, REAL kinds 4/8, DIM reductions, empty enclosing arrays, unevaluated KIND, scalar assignment, and distinct true array results. All 49 synthetic cases execute successfully under GNU Fortran. The immutable certified 0.45 executable is retained as a negative control: 36 cases reproduce the exact runtime regression, while the other 13 controls pass. No historical source fixture is edited.

The focused native program uses the public constant-array evaluator to exercise successive enclosing positions and checks that forged scalar metadata for true array results, wrong array shape caches and out-of-range element accesses still fail. The existing matrix/norm malformed-IR program is also rerun unchanged.

Development validation uses one standard-debug app/library build containing this narrow fix plus the independent bounds-inquiry feature. This is explicitly a combined candidate, not a separate clean release certification. The correction's core patch contains only its three added dispatch lines; full 0.46 integration validation remains separate.
