# Bounded array-valued function results

Ordinary (non-ELEMENTAL) functions may return INTEGER(4/8), REAL(4/8), or
LOGICAL arrays of rank one or two. The result has an explicit-shape declaration
using either the function name or an explicit RESULT name. Bounds can be constants
or the supported automatic-array specification expressions described in
[AUTOMATIC-ARRAYS.md](AUTOMATIC-ARRAYS.md). This includes integer scalar dummy
arguments, SIZE inquiries on assumed-shape array dummies, and scalar COUNT
reductions of supported input masks.

```fortran
pure function differences(x) result(y)
    real(8), intent(in) :: x(:)
    real(8) :: y(size(x)-1)
    integer :: n
    n = size(x)
    if (n > 1) y = x(2:) - x(:n-1)
end function
```

Result arrays can participate in assignment, arithmetic, constructors, reductions,
SIZE/LBOUND/UBOUND, supported generic and defined-operator calls, and read-only
array actual argument association. Nested result expressions and calls repeated
with different shapes are supported. A result declaration's lower bounds apply
inside its function; outside it, the function expression has lower bounds of one.
Rank and element type/kind are declaration-derived, independently checked by the
frontend adapter. Runtime extents come from the completed invocation's descriptor.
KIND inquiries use type metadata and do not execute the function or read its
actual argument data.

## Ownership, initialization and checks

All actual arguments are bound before automatic result/local bounds are evaluated.
The bounds are fixed for that invocation. The body runs once per array-function
expression occurrence per executed statement, including a zero-element result.
Each result element must be defined when the body returns. Empty results require
no element definitions, but do not suppress a body ERROR STOP or other error.

After successful result validation, the invocation transfers ownership of its
result allocation to its caller. No result points into a completed frame. The
caller caches that whole result until the end of the current statement, so a
reduction/product or repeated element traversal cannot rerun the body. Different
expression occurrences are distinct invocations. Cached results are discarded
between statements, including loop iterations.

Array result values and shapes are resolved before assignment commits, retaining
existing overlap-safe behavior. Nonconforming shapes, partially initialized
results, unsupported bounds, out-of-range extents and work-limit failures are
checked errors. Frame arrays (including dummy copies, locals and result storage)
share max_array_elements, currently 1,000,000. Array actuals have their configured
per-call cap. Materialized function results share the same cap per caller
statement with IMPURE ELEMENTAL result temporaries. These are bounded interpreter
safety policies, not claims about compiler evaluation choices.

Numeric allocatable deferred-shape results are supported as described in
[ALLOCATABLE-ASSIGNMENT.md](ALLOCATABLE-ASSIGNMENT.md). Derived-type array results, rank four and higher, POINTER results, and other deferred
shapes remain unsupported. Explicit bounded RECURSIVE procedures are supported; see [RECURSION.md](RECURSION.md). ELEMENTAL functions still require a scalar declared result.
Typed-header plus separate DIMENSION statements are not added.

## Verification

`tests/array_results/run_tests.py` checks normal outputs against independently
specified values and GNU Fortran (`-std=f2018 -pedantic-errors -fcheck=all -O0`).
Policy failures are distinguished from GNU compile/run oracles. The suite covers
rank-one/rank-two values and bounds, INTEGER(8)/REAL(8)/LOGICAL, zero extents,
sections, nested calls, repeated calls, generics, named operators, early RETURN,
partial initialization, shape/temporary/frame limits and KIND non-evaluation.
`test/test_array_results.f90` independently corrupts IR metadata and checks that
both adapter and runtime reject it.

`tests/array_results/original_utilities.f90` retains the original bodies of
normalize, diff_vector_int, diff_vector_real, diff_matrix_real, growing_mean_vec
and num_obs_bins from the supplied xutilities.f90. Only the containing module,
required constants and test driver are supplied by the fixture. This does not
claim support for the entire original utilities module.

CHARACTER array results, including bounded runtime element lengths, are now
supported as described in [CHARACTER-PROCEDURES.md](CHARACTER-PROCEDURES.md).
